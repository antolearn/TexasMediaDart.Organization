using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Abstractions;

public interface IRoleRepository
{
    Task<RoleSearchResultDto> SearchAsync(
        Guid organizationId,
        string? searchText,
        bool? isSystemRole,
        bool? isActive,
        bool? isApproved,
        bool includeDeleted,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<RoleDto?> GetByIdAsync(
        Guid roleId,
        Guid organizationId,
        CancellationToken cancellationToken = default);

    Task<RoleDto> CreateAsync(
        Guid roleId,
        Guid organizationId,
        string name,
        string? description,
        string createdBy,
        CancellationToken cancellationToken = default);

    Task<RoleDto> UpdateAsync(
        Guid roleId,
        Guid organizationId,
        string name,
        string? description,
        bool isActive,
        string modifiedBy,
        CancellationToken cancellationToken = default);

    Task<RoleDto> DeleteAsync(
        Guid roleId,
        Guid organizationId,
        string deletedBy,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RolePermissionDto>> GetPermissionsAsync(
        Guid roleId,
        Guid organizationId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RolePermissionDto>> UpdatePermissionsAsync(
        Guid roleId,
        Guid organizationId,
        IReadOnlyCollection<RolePermissionInputDto> permissions,
        string modifiedBy,
        CancellationToken cancellationToken = default);
}