using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using TexasMediaDart.Organization.Application.Common.Exceptions;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Infrastructure.UserGroups;

public sealed class UserGroupRepository : IUserGroupRepository
{
    private readonly string _connectionString;

    public UserGroupRepository(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");
    }

    public async Task<UserGroupSearchResultDto> SearchAsync(
        Guid organizationId,
        string? searchText,
        bool? isActive,
        bool? isApproved,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroup_Search]",
            parameters: new
            {
                OrganizationId = organizationId,
                SearchText = searchText,
                IsActive = isActive,
                IsApproved = isApproved,
                PageNumber = pageNumber,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        using var result =
            await connection.QueryMultipleAsync(command);

        var userGroups =
            (await result.ReadAsync<UserGroupDto>())
            .AsList();

        var totalCount =
            await result.ReadSingleAsync<long>();

        return new UserGroupSearchResultDto
        {
            Items = userGroups,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }

    public async Task<UserGroupDto?> GetByIdAsync(
        Guid userGroupId,
        Guid organizationId,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroup_GetById]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationId = organizationId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleOrDefaultAsync<UserGroupDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 55101 or 55102)
        {
            throw new ValidationException(ex.Message);
        }
    }

    public async Task<UserGroupDto> CreateAsync(
        Guid userGroupId,
        Guid organizationId,
        string name,
        string? description,
        string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroup_Create]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationId = organizationId,
                Name = name,
                Description = description,
                CreatedBy = createdBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<UserGroupDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 55001 or 55002 or 55003 or 55004)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55005)
        {
            throw new NotFoundException(
                "The organization does not exist or is inactive.");
        }
        catch (SqlException ex) when (ex.Number == 55006)
        {
            throw new ConflictException(
                "A user group with this name already exists in the organization.");
        }
    }

    public async Task<UserGroupDto> UpdateAsync(
        Guid userGroupId,
        Guid organizationId,
        string name,
        string? description,
        bool isActive,
        string modifiedBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroup_Update]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationId = organizationId,
                Name = name,
                Description = description,
                IsActive = isActive,
                ModifiedBy = modifiedBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<UserGroupDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 55301 or 55302 or 55303 or 55304)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55305)
        {
            throw new NotFoundException(
                "The user group does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 55306)
        {
            throw new ConflictException(
                "A user group with this name already exists in the organization.");
        }
    }

    public async Task<UserGroupDto> DeleteAsync(
        Guid userGroupId,
        Guid organizationId,
        string deletedBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroup_Delete]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationId = organizationId,
                ModifiedBy = deletedBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<UserGroupDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 55401 or 55402 or 55403)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55404)
        {
            throw new NotFoundException(
                "The user group does not exist in this organization.");
        }
    }

    public async Task<UserGroupMemberSearchResultDto> SearchMembersAsync(
    Guid userGroupId,
    Guid organizationId,
    bool? isActive,
    bool? isApproved,
    int pageNumber,
    int pageSize,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroupMember_Search]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationId = organizationId,
                IsActive = isActive,
                IsApproved = isApproved,
                PageNumber = pageNumber,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            using var result =
                await connection.QueryMultipleAsync(command);

            var members =
                (await result.ReadAsync<UserGroupMemberDto>())
                .AsList();

            var totalCount =
                await result.ReadSingleAsync<long>();

            return new UserGroupMemberSearchResultDto
            {
                Items = members,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        catch (SqlException ex) when (
            ex.Number is 55701 or 55702 or 55703 or 55704)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55705)
        {
            throw new NotFoundException(
                "The user group does not exist in this organization.");
        }
    }
    public async Task<UserGroupMemberCreatedDto> AddMemberAsync(
        Guid userGroupId,
        long organizationUserId,
        Guid organizationId,
        string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroupMember_Add]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationUserId = organizationUserId,
                OrganizationId = organizationId,
                CreatedBy = createdBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection
                .QuerySingleAsync<UserGroupMemberCreatedDto>(
                    command);
        }
        catch (SqlException ex) when (
            ex.Number is 55501 or 55502 or 55503 or 55504)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55505)
        {
            throw new NotFoundException(
                "The user group does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 55506)
        {
            throw new NotFoundException(
                "The organization user does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 55507)
        {
            throw new ConflictException(
                "The user is already a member of this user group.");
        }
    }
    public async Task RemoveMemberAsync(
        Guid userGroupId,
        long organizationUserId,
        Guid organizationId,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_UserGroupMember_Remove]",
            parameters: new
            {
                UserGroupId = userGroupId,
                OrganizationUserId = organizationUserId,
                OrganizationId = organizationId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            await connection.ExecuteAsync(command);
        }
        catch (SqlException ex) when (
            ex.Number is 55601 or 55602 or 55603)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 55604)
        {
            throw new NotFoundException(
                "The user group does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 55605)
        {
            throw new NotFoundException(
                "The organization user does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 55606)
        {
            throw new NotFoundException(
                "The user is not a member of this user group.");
        }
    }

}