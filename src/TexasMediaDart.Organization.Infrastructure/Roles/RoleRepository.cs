using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using TexasMediaDart.Organization.Application.Common.Exceptions;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Infrastructure.Roles;

public sealed class RoleRepository : IRoleRepository
{
    private readonly string _connectionString;

    public RoleRepository(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured.");
    }

    public async Task<RoleSearchResultDto> SearchAsync(
        Guid organizationId,
        string? searchText,
        bool? isSystemRole,
        bool? isActive,
        bool? isApproved,
        bool includeDeleted,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_Search]",
            parameters: new
            {
                OrganizationId = organizationId,
                SearchText = searchText,
                IsSystemRole = isSystemRole,
                IsActive = isActive,
                IsApproved = isApproved,
                IncludeDeleted = includeDeleted,
                PageNumber = pageNumber,
                PageSize = pageSize
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        using var result =
            await connection.QueryMultipleAsync(command);

        var roles =
            (await result.ReadAsync<RoleDto>())
            .AsList();

        var totalCount =
            await result.ReadSingleAsync<long>();

        return new RoleSearchResultDto
        {
            Items = roles,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }
    public async Task<RoleDto?> GetByIdAsync(
        Guid roleId,
        Guid organizationId,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_GetById]",
            parameters: new
            {
                RoleId = roleId,
                OrganizationId = organizationId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        return await connection.QuerySingleOrDefaultAsync<RoleDto>(
            command);
    }

    public async Task<RoleDto> CreateAsync(
        Guid roleId,
        Guid organizationId,
        string name,
        string? description,
        string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_Create]",
            parameters: new
            {
                RoleId = roleId,
                OrganizationId = organizationId,
                Name = name,
                Description = description,
                CreatedBy = createdBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<RoleDto>(
                command);
        }
        catch (SqlException ex) when (ex.Number == 54007)
        {
            throw new ConflictException(
                "A role with this name already exists in the organization.");
        }
    }

    public async Task<RoleDto> UpdateAsync(
        Guid roleId,
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
            commandText: "[dbo].[sp_Role_Update]",
            parameters: new
            {
                RoleId = roleId,
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
            return await connection.QuerySingleAsync<RoleDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 54301 or 54302 or 54303 or 54304)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 54305)
        {
            throw new NotFoundException(
                "The role does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 54306)
        {
            throw new ConflictException(
                "System roles cannot be modified through ordinary role management.");
        }
        catch (SqlException ex) when (ex.Number == 54307)
        {
            throw new ValidationException(
                "Owner is a reserved system role name.");
        }
        catch (SqlException ex) when (ex.Number == 54308)
        {
            throw new ConflictException(
                "A role with this name already exists in the organization.");
        }
    }

    public async Task<RoleDto> DeleteAsync(
        Guid roleId,
        Guid organizationId,
        string deletedBy,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_Delete]",
            parameters: new
            {
                RoleId = roleId,
                OrganizationId = organizationId,
                ModifiedBy = deletedBy
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<RoleDto>(
                command);
        }
        catch (SqlException ex) when (
            ex.Number is 54401 or 54402 or 54403)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 54404)
        {
            throw new NotFoundException(
                "The role does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 54405)
        {
            throw new ConflictException(
                "System roles cannot be deleted.");
        }
        catch (SqlException ex) when (ex.Number == 54406)
        {
            throw new ConflictException(
                "The role cannot be deleted because it is assigned to one or more users.");
        }
    }

    public async Task<IReadOnlyList<RolePermissionDto>>
        GetPermissionsAsync(
            Guid roleId,
            Guid organizationId,
            CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_GetPermissions]",
            parameters: new
            {
                RoleId = roleId,
                OrganizationId = organizationId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            var permissions =
                await connection.QueryAsync<RolePermissionDto>(
                    command);

            return permissions.AsList();
        }
        catch (SqlException ex) when (
            ex.Number is 54501 or 54502)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 54503)
        {
            throw new NotFoundException(
                "The role does not exist in this organization.");
        }
    }

    public async Task<IReadOnlyList<RolePermissionDto>>
        UpdatePermissionsAsync(
            Guid roleId,
            Guid organizationId,
            IReadOnlyCollection<RolePermissionInputDto> permissions,
            string modifiedBy,
            CancellationToken cancellationToken = default)
    {
        await using var connection =
            new SqlConnection(_connectionString);

        var permissionTable =
            CreatePermissionTable(permissions);

        var parameters =
            new DynamicParameters();

        parameters.Add(
            "RoleId",
            roleId,
            DbType.Guid);

        parameters.Add(
            "OrganizationId",
            organizationId,
            DbType.Guid);

        parameters.Add(
            "Permissions",
            permissionTable.AsTableValuedParameter(
                "[dbo].[RolePermissionInputType]"));

        parameters.Add(
            "ModifiedBy",
            modifiedBy,
            DbType.String,
            size: 100);

        var command = new CommandDefinition(
            commandText: "[dbo].[sp_Role_UpdatePermissions]",
            parameters: parameters,
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        try
        {
            var result =
                await connection.QueryAsync<RolePermissionDto>(
                    command);

            return result.AsList();
        }
        catch (SqlException ex) when (
            ex.Number is 54601 or 54602 or 54603)
        {
            throw new ValidationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 54604)
        {
            throw new NotFoundException(
                "The role does not exist in this organization.");
        }
        catch (SqlException ex) when (ex.Number == 54605)
        {
            throw new ConflictException(
                "System role permissions cannot be modified.");
        }
        catch (SqlException ex) when (
            ex.Number is 54606 or 54607 or 54608 or 54609)
        {
            throw new ValidationException(ex.Message);
        }
    }
    private static DataTable CreatePermissionTable(
        IEnumerable<RolePermissionInputDto> permissions)
    {
        var table =
            new DataTable();

        table.Columns.Add(
            "ModuleId",
            typeof(int));

        table.Columns.Add(
            "CanCreate",
            typeof(bool));

        table.Columns.Add(
            "CanUpdate",
            typeof(bool));

        table.Columns.Add(
            "CanDelete",
            typeof(bool));

        table.Columns.Add(
            "CanRead",
            typeof(bool));

        table.Columns.Add(
            "CanApprove",
            typeof(bool));

        foreach (var permission in permissions)
        {
            table.Rows.Add(
                permission.ModuleId,
                permission.CanCreate,
                permission.CanUpdate,
                permission.CanDelete,
                permission.CanRead,
                permission.CanApprove);
        }

        return table;
    }
}