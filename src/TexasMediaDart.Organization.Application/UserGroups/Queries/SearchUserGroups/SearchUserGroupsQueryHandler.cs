using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroups;

public sealed class SearchUserGroupsQueryHandler
    : IQueryHandler<SearchUserGroupsQuery, UserGroupSearchResultDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public SearchUserGroupsQueryHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupSearchResultDto> HandleAsync(
        SearchUserGroupsQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(query.OrganizationId));
        }

        var searchText =
            string.IsNullOrWhiteSpace(query.SearchText)
                ? null
                : query.SearchText.Trim();

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

        return await _userGroupRepository.SearchAsync(
            query.OrganizationId,
            searchText,
            query.IsActive,
            query.IsApproved,
            query.IncludeDeleted,
            pageNumber,
            pageSize,
            cancellationToken);
    }
}