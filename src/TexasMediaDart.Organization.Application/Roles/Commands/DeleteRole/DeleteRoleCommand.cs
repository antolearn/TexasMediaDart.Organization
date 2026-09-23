using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.DeleteRole;

public sealed record DeleteRoleCommand(
    Guid RoleId,
    Guid OrganizationId,
    string DeletedBy)
    : ICommand<RoleDto>;