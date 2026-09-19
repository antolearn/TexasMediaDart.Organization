namespace TexasMediaDart.Organization.Application.Users.Models;

public sealed class OrganizationUserSearchResultDto
{
    public IReadOnlyList<OrganizationUserDto> Items { get; init; } =
        Array.Empty<OrganizationUserDto>();

    public long TotalCount { get; init; }

    public int PageNumber { get; init; }

    public int PageSize { get; init; }
}