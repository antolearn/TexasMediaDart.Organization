using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroups;

public sealed class SearchUserGroupsQueryHandler
    : IQueryHandler<SearchUserGroupsQuery, UserGroupSearchResultDto>
{
    private static readonly HashSet<string> AllowedSortFields =
        new(StringComparer.OrdinalIgnoreCase)
        {
            "name",
            "description",
            "createdUtc"
        };

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

        var sortBy =
            string.IsNullOrWhiteSpace(query.SortBy)
                ? null
                : query.SortBy.Trim();

        var sortDirection =
            string.IsNullOrWhiteSpace(query.SortDirection)
                ? null
                : query.SortDirection.Trim().ToLowerInvariant();

        if (sortBy is not null &&
            !AllowedSortFields.Contains(sortBy))
        {
            throw new ArgumentException(
                "SortBy must be name, description, or createdUtc.",
                nameof(query.SortBy));
        }

        if (sortDirection is not null &&
            sortDirection is not ("asc" or "desc"))
        {
            throw new ArgumentException(
                "SortDirection must be asc or desc.",
                nameof(query.SortDirection));
        }

        if (sortBy is null && sortDirection is not null)
        {
            throw new ArgumentException(
                "SortBy is required when SortDirection is provided.",
                nameof(query.SortBy));
        }

        if (sortBy is not null && sortDirection is null)
        {
            sortDirection =
                sortBy.Equals(
                    "createdUtc",
                    StringComparison.OrdinalIgnoreCase)
                    ? "desc"
                    : "asc";
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

        return await _userGroupRepository.SearchAsync(
            query.OrganizationId,
            searchText,
            query.IsActive,
            query.IsApproved,
            query.IncludeDeleted,
            sortBy,
            sortDirection,
            pageNumber,
            pageSize,
            cancellationToken);
    }
}