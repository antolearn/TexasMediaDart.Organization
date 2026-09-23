using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.SearchRoles;

public sealed record SearchRolesQuery(
    Guid OrganizationId,
    string? SearchText,
    bool? IsSystemRole,
    bool? IsActive,
    bool? IsApproved,
    int PageNumber,
    int PageSize)
    : IQuery<RoleSearchResultDto>;