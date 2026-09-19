using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Infrastructure.Users;

public sealed class UserRepository : IUserRepository
{
    private readonly string _connectionString;

    public UserRepository(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");
    }

    public async Task<OrganizationUserSearchResultDto> SearchAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_OrganizationUser_Search]",
            parameters: new
            {
                OrganizationId = organizationId,
                IdentityUserId = identityUserId,
                IsActive = isActive,
                IsApproved = isApproved,
                PageNumber = pageNumber,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        using var multi =
            await connection.QueryMultipleAsync(command);

        var users =
            (await multi.ReadAsync<OrganizationUserDto>())
            .AsList();

        var totalCount =
            await multi.ReadSingleAsync<long>();

        return new OrganizationUserSearchResultDto
        {
            Items = users,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }
}