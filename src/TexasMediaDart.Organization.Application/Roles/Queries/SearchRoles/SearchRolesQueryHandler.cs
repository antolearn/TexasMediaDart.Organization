using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.SearchRoles;

public sealed class SearchRolesQueryHandler
    : IQueryHandler<SearchRolesQuery, RoleSearchResultDto>
{
    private readonly IRoleRepository _roleRepository;

    public SearchRolesQueryHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<RoleSearchResultDto> HandleAsync(
        SearchRolesQuery query,
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

        return await _roleRepository.SearchAsync(
            query.OrganizationId,
            searchText,
            query.IsSystemRole,
            query.IsActive,
            query.IsApproved,
            query.IncludeDeleted,
            pageNumber,
            pageSize,
            cancellationToken);
    }
}