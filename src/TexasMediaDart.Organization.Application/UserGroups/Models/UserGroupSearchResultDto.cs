namespace TexasMediaDart.Organization.Application.UserGroups.Models;

public sealed class UserGroupSearchResultDto
{
    public IReadOnlyList<UserGroupDto> Items { get; init; } =
        Array.Empty<UserGroupDto>();

    public long TotalCount { get; init; }

    public int PageNumber { get; init; }

    public int PageSize { get; init; }
}