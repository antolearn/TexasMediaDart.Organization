using System.Reflection;
using Microsoft.Data.SqlClient;

namespace TexasMediaDart.Organization.Api.Extensions;

public static class HealthEndpointExtensions
{
    public static WebApplication MapHealthEndpoints(
        this WebApplication app)
    {
        app.MapGet("/health/api", () =>
        {
            return Results.Ok(new
            {
                status = "Healthy",
                service = "TexasMediaDart.Organization.Api",
                timestampUtc = DateTime.UtcNow
            });
        });
        app.MapGet("/health/db", async (IConfiguration configuration) =>
        {
            var connectionString =
                configuration.GetConnectionString("DefaultConnection");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return Results.Problem(
                    title: "Database health check failed",
                    detail: "DefaultConnection is not configured.",
                    statusCode: StatusCodes.Status500InternalServerError);
            }

            try
            {
                await using var connection =
                    new SqlConnection(connectionString);

                await connection.OpenAsync();

                await using var command =
                    new SqlCommand(
                        """
                        SELECT
                            DB_NAME() AS DatabaseName,
                            (
                                SELECT TOP (1) [Version]
                                FROM dbo.DatabaseVersion
                                WHERE Id = 1
                            ) AS DatabaseVersion;
                        """,
                        connection);

                await using var reader =
                    await command.ExecuteReaderAsync();

                string? databaseName = null;
                string? databaseVersion = null;

                if (await reader.ReadAsync())
                {
                    databaseName =
                        reader["DatabaseName"]?.ToString();

                    databaseVersion =
                        reader["DatabaseVersion"] == DBNull.Value
                            ? null
                            : reader["DatabaseVersion"]?.ToString();
                }

                return Results.Ok(new
                {
                    status = "Healthy",
                    database = databaseName,
                    databaseVersion = databaseVersion ?? "Not deployed",
                    timestampUtc = DateTime.UtcNow
                });
            }
            catch (Exception exception)
            {
                return Results.Problem(
                    title: "Database health check failed",
                    detail: exception.Message,
                    statusCode: StatusCodes.Status503ServiceUnavailable);
            }
        });

        app.MapGet("/health/version", (IHostEnvironment environment) =>
        {
            var assembly = Assembly.GetExecutingAssembly();

            var version =
                assembly
                    .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
                    ?.InformationalVersion
                ?? "unknown";

            return Results.Ok(new
            {
                application = "TexasMediaDart.Organization.Api",
                version,
                environment = environment.EnvironmentName,
                timestampUtc = DateTime.UtcNow
            });
        });

        return app;
    }
}