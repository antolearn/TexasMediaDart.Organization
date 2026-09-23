using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.GetRolePermissions;

public sealed class GetRolePermissionsQueryHandler
    : IQueryHandler<
        GetRolePermissionsQuery,
        IReadOnlyList<RolePermissionDto>>
{
    private readonly IRoleRepository _roleRepository;

    public GetRolePermissionsQueryHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<IReadOnlyList<RolePermissionDto>> HandleAsync(
        GetRolePermissionsQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.RoleId == Guid.Empty)
        {
            throw new ArgumentException(
                "RoleId is required.",
                nameof(query.RoleId));
        }

        if (query.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(query.OrganizationId));
        }

        return await _roleRepository.GetPermissionsAsync(
            query.RoleId,
            query.OrganizationId,
            cancellationToken);
    }
}