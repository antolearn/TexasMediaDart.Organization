using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.GetRoleById;

public sealed record GetRoleByIdQuery(
    Guid RoleId,
    Guid OrganizationId)
    : IQuery<RoleDto?>;