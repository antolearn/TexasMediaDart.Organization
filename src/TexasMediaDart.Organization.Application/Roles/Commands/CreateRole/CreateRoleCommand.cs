using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.CreateRole;

public sealed record CreateRoleCommand(
    Guid OrganizationId,
    string Name,
    string? Description,
    string CreatedBy)
    : ICommand<RoleDto>;