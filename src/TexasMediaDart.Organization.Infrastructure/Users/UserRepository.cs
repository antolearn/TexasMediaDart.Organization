using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;
using TexasMediaDart.Organization.Application.Common.Exceptions;

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

    public async Task<OrganizationUserDto> CreateAsync(
    Guid organizationId,
    Guid identityUserId,
    string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_OrganizationUser_Create]",
            parameters: new
            {
                OrganizationId = organizationId,
                IdentityUserId = identityUserId,
                CreatedBy = createdBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<OrganizationUserDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 53001 or 53002 or 53003)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 53004)
        {
            throw new NotFoundException(
                "The organization does not exist or is inactive.");
        }
        catch (SqlException ex) when (ex.Number == 53005)
        {
            throw new ConflictException(
                "The identity user already belongs to an organization.");
        }
    }
    public async Task<OrganizationUserSearchResultDto> SearchAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        bool filterByIdentityUserIds,
        IReadOnlyCollection<Guid> identityUserIds,
        string sortBy,
        string sortDirection,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var identityUserIdsTable = new DataTable();
        identityUserIdsTable.Columns.Add("Id", typeof(Guid));

        foreach (var id in identityUserIds.Distinct())
        {
            identityUserIdsTable.Rows.Add(id);
        }

        var parameters = new DynamicParameters();

        parameters.Add(
            "@OrganizationId",
            organizationId);

        parameters.Add(
            "@IdentityUserId",
            identityUserId);

        parameters.Add(
            "@IsActive",
            isActive);

        parameters.Add(
            "@IsApproved",
            isApproved);

        parameters.Add(
            "@FilterByIdentityUserIds",
            filterByIdentityUserIds);

        parameters.Add(
            "@IdentityUserIds",
            identityUserIdsTable.AsTableValuedParameter("dbo.GuidList"));

        parameters.Add(
            "@SortBy",
            sortBy);

        parameters.Add(
            "@SortDirection",
            sortDirection);

        parameters.Add(
            "@PageNumber",
            pageNumber);

        parameters.Add(
            "@PageSize",
            pageSize);

        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_OrganizationUser_Search]",
            parameters: parameters,
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
    public async Task<IReadOnlyList<Guid>> GetCandidateIdentityUserIdsAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText:
                "[dbo].[sp_OrganizationUser_GetCandidateIdentityUserIds]",
            parameters: new
            {
                OrganizationId = organizationId,
                IdentityUserId = identityUserId,
                IsActive = isActive,
                IsApproved = isApproved
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        var identityUserIds =
            await connection.QueryAsync<Guid>(command);

        return identityUserIds.AsList();
    }
}