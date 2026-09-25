namespace TexasMediaDart.Organization.Application.UserGroups.Models;

public sealed class UserGroupMemberSearchResultDto
{
    public IReadOnlyList<UserGroupMemberDto> Items { get; init; } =
        Array.Empty<UserGroupMemberDto>();

    public long TotalCount { get; init; }

    public int PageNumber { get; init; }

    public int PageSize { get; init; }
}