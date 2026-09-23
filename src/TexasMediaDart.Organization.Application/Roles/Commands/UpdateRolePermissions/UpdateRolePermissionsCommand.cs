using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.UpdateRolePermissions;

public sealed record UpdateRolePermissionsCommand(
    Guid RoleId,
    Guid OrganizationId,
    IReadOnlyCollection<RolePermissionInputDto> Permissions,
    string ModifiedBy)
    : ICommand<IReadOnlyList<RolePermissionDto>>;