namespace TexasMediaDart.Organization.Application.Roles.Models;

public sealed class RoleSearchResultDto
{
    public IReadOnlyList<RoleDto> Items { get; init; } =
        Array.Empty<RoleDto>();

    public long TotalCount { get; init; }

    public int PageNumber { get; init; }

    public int PageSize { get; init; }
}