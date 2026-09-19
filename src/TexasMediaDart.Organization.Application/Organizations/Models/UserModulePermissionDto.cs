namespace TexasMediaDart.Organization.Application.Organizations.Models;

public sealed class UserModulePermissionDto
{
    public Guid OrganizationId { get; init; }

    public long OrganizationUserId { get; init; }

    public int ModuleId { get; init; }

    public string ModuleCode { get; init; } = string.Empty;

    public string ModuleName { get; init; } = string.Empty;

    public string? Description { get; init; }

    public string? Route { get; init; }

    public string? IconKey { get; init; }

    public string? MenuGroup { get; init; }

    public int DisplayOrder { get; init; }

    public bool ShowInMenu { get; init; }

    public bool CanCreate { get; init; }

    public bool CanUpdate { get; init; }

    public bool CanDelete { get; init; }

    public bool CanRead { get; init; }
}