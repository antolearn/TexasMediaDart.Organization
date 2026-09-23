using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.UpdateRole;

public sealed record UpdateRoleCommand(
    Guid RoleId,
    Guid OrganizationId,
    string Name,
    string? Description,
    bool IsActive,
    string ModifiedBy)
    : ICommand<RoleDto>;