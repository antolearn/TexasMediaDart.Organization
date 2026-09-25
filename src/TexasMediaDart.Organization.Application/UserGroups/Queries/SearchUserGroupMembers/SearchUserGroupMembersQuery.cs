using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroupMembers;

public sealed record SearchUserGroupMembersQuery(
    Guid UserGroupId,
    Guid OrganizationId,
    bool? IsActive,
    bool? IsApproved,
    int PageNumber,
    int PageSize)
    : IQuery<UserGroupMemberSearchResultDto>;