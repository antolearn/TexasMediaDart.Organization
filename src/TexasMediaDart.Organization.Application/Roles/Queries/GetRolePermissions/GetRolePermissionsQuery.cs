using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.GetRolePermissions;

public sealed record GetRolePermissionsQuery(
    Guid RoleId,
    Guid OrganizationId)
    : IQuery<IReadOnlyList<RolePermissionDto>>;