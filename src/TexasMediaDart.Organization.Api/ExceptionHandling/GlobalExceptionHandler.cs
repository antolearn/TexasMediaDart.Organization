using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using TexasMediaDart.Organization.Application.Common.Exceptions;

namespace TexasMediaDart.Organization.Api.ExceptionHandling;

public sealed class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(
        ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var problemDetails = exception switch
        {
            ConflictException conflictException =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Conflict",
                    Detail = conflictException.Message
                },

            ArgumentException argumentException =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Invalid request",
                    Detail = argumentException.Message
                },

            SqlException sqlException
                when sqlException.Number == 51000 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Invalid request",
                    Detail = sqlException.Message
                },

            SqlException sqlException
                when sqlException.Number == 51001 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Organization conflict",
                    Detail = sqlException.Message
                },

            SqlException sqlException
                when sqlException.Number == 51002 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Organization name conflict",
                    Detail = sqlException.Message
                },

            SqlException sqlException
                when sqlException.Number == 51004 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Data conflict",
                    Detail = sqlException.Message
                },

            SqlException sqlException
                when sqlException.Number is 2601 or 2627 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Data conflict",
                    Detail = "The requested operation conflicts with existing data."
                },

            SqlException sqlException
                when sqlException.Number == 51003 =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status500InternalServerError,
                    Title = "Organization configuration error",
                    Detail = "The organization could not be created because the CORE license is not configured."
                },

            _ =>
                new ProblemDetails
                {
                    Status = StatusCodes.Status500InternalServerError,
                    Title = "An unexpected error occurred.",
                    Detail = "The server encountered an unexpected error while processing the request."
                }
        };

        problemDetails.Type =
            $"https://httpstatuses.com/{problemDetails.Status}";

        problemDetails.Instance =
            httpContext.Request.Path;

        if (problemDetails.Status >= 500)
        {
            _logger.LogError(
                exception,
                "Unhandled exception while processing {Method} {Path}",
                httpContext.Request.Method,
                httpContext.Request.Path);
        }
        else
        {
            _logger.LogWarning(
                exception,
                "Request failed with status {StatusCode}: {Method} {Path}",
                problemDetails.Status,
                httpContext.Request.Method,
                httpContext.Request.Path);
        }

        httpContext.Response.StatusCode =
            problemDetails.Status
            ?? StatusCodes.Status500InternalServerError;

        await httpContext.Response.WriteAsJsonAsync(
            problemDetails,
            cancellationToken);

        return true;
    }
}