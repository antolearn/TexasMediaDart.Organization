using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroups;

public sealed record SearchUserGroupsQuery(
    Guid OrganizationId,
    string? SearchText,
    bool? IsActive,
    bool? IsApproved,
    int PageNumber,
    int PageSize)
    : IQuery<UserGroupSearchResultDto>;