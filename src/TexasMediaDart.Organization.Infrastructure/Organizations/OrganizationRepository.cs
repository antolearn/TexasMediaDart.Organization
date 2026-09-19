using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Infrastructure.Organizations;

public sealed class OrganizationRepository : IOrganizationRepository
{
    private readonly string _connectionString;

    public OrganizationRepository(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");
    }

    public async Task<CurrentOrganizationDto?> GetCurrentAsync(
        Guid identityUserId,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Organization_GetCurrent]",
            parameters: new
            {
                IdentityUserId = identityUserId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        return await connection.QuerySingleOrDefaultAsync<CurrentOrganizationDto>(
            command);
    }
    public async Task<CreateOrganizationResultDto> CreateAsync(
    Guid organizationId,
    string name,
    Guid identityUserId,
    string userEmail,
    CancellationToken cancellationToken = default)
{
    await using var connection =
        new SqlConnection(_connectionString);

    var command = new CommandDefinition(
        commandText: "[dbo].[sp_Organization_Create]",
        parameters: new
        {
            OrganizationId = organizationId,
            Name = name,
            IdentityUserId = identityUserId,
            UserEmail = userEmail
        },
        commandType: CommandType.StoredProcedure,
        cancellationToken: cancellationToken);

    return await connection.QuerySingleAsync<CreateOrganizationResultDto>(
        command);
}
public async Task<IReadOnlyList<UserModulePermissionDto>> GetUserModulesAsync(
    Guid identityUserId,
    CancellationToken cancellationToken = default)
{
    await using var connection =
        new SqlConnection(_connectionString);

    var command = new CommandDefinition(
        commandText: "[dbo].[sp_User_GetEffectiveModulePermissions]",
        parameters: new
        {
            IdentityUserId = identityUserId
        },
        commandType: CommandType.StoredProcedure,
        cancellationToken: cancellationToken);

    var modules =
        await connection.QueryAsync<UserModulePermissionDto>(command);

    return modules.AsList();
}
}