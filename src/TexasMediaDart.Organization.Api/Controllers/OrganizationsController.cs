using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;
using TexasMediaDart.Organization.Application.Organizations.Models;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class OrganizationsController : ControllerBase
{
    private readonly IQueryHandler<
        GetCurrentOrganizationQuery,
        CurrentOrganizationDto?> _getCurrentOrganizationHandler;

    private readonly ICommandHandler<
        CreateOrganizationCommand,
        CreateOrganizationResultDto> _createOrganizationHandler;

    public OrganizationsController(
        IQueryHandler<
            GetCurrentOrganizationQuery,
            CurrentOrganizationDto?> getCurrentOrganizationHandler,
        ICommandHandler<
            CreateOrganizationCommand,
            CreateOrganizationResultDto> createOrganizationHandler)
    {
        _getCurrentOrganizationHandler = getCurrentOrganizationHandler;
        _createOrganizationHandler = createOrganizationHandler;
    }

    [HttpGet("current")]
    public async Task<IActionResult> GetCurrent(
        CancellationToken cancellationToken)
    {
        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(identityUserIdValue, out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var query =
            new GetCurrentOrganizationQuery(identityUserId);

        var organization =
            await _getCurrentOrganizationHandler.HandleAsync(
                query,
                cancellationToken);

        if (organization is null)
        {
            return NotFound(new
            {
                message =
                    "No organization is associated with the authenticated user."
            });
        }

        return Ok(organization);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateOrganizationRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new
            {
                message = "Organization name is required."
            });
        }

        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(identityUserIdValue, out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var email =
            User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");

        if (string.IsNullOrWhiteSpace(email))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain an email address."
            });
        }

        var command =
            new CreateOrganizationCommand(
                request.Name,
                identityUserId,
                email);

        var result =
            await _createOrganizationHandler.HandleAsync(
                command,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetCurrent),
            null,
            result);
    }
}

public sealed class CreateOrganizationRequest
{
    public string Name { get; init; } = string.Empty;
}