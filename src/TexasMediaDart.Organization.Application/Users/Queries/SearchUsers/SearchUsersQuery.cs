using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;

public sealed record SearchUsersQuery(
    Guid IdentityUserId,
    Guid? FilterIdentityUserId,
    bool? IsActive,
    bool? IsApproved,
    bool FilterByIdentityUserIds,
    IReadOnlyCollection<Guid> IdentityUserIds,
    string SortBy,
    string SortDirection,
    int PageNumber,
    int PageSize)
    : IQuery<OrganizationUserSearchResultDto>;