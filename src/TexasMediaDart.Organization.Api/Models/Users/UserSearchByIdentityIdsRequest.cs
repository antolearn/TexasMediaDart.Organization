namespace TexasMediaDart.Organization.Api.Models.Users;

public sealed class UserSearchByIdentityIdsRequest
{
    public IReadOnlyCollection<Guid> IdentityUserIds { get; init; }
        = Array.Empty<Guid>();

    public Guid? IdentityUserId { get; init; }

    public bool? IsActive { get; init; }

    public bool? IsApproved { get; init; }

    public string SortBy { get; init; } = "createdUtc";

    public string SortDirection { get; init; } = "desc";

    public int PageNumber { get; init; } = 1;

    public int PageSize { get; init; } = 25;
}