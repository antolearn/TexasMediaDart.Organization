using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroupMembers;

public sealed class SearchUserGroupMembersQueryHandler
    : IQueryHandler<SearchUserGroupMembersQuery, UserGroupMemberSearchResultDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public SearchUserGroupMembersQueryHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupMemberSearchResultDto> HandleAsync(
        SearchUserGroupMembersQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.UserGroupId == Guid.Empty)
        {
            throw new ArgumentException(
                "UserGroupId is required.",
                nameof(query.UserGroupId));
        }

        if (query.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(query.OrganizationId));
        }

        var pageNumber =
            query.PageNumber < 1
                ? 1
                : query.PageNumber;

        var pageSize =
            query.PageSize switch
            {
                < 1 => 25,
                > 100 => 100,
                _ => query.PageSize
            };

        return await _userGroupRepository.SearchMembersAsync(
            query.UserGroupId,
            query.OrganizationId,
            query.IsActive,
            query.IsApproved,
            pageNumber,
            pageSize,
            cancellationToken);
    }
}