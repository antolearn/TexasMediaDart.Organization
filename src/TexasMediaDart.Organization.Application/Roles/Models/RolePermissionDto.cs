namespace TexasMediaDart.Organization.Application.Roles.Models;

public sealed class RolePermissionDto
{
    public Guid RoleId { get; init; }

    public int ModuleId { get; init; }

    public string ModuleCode { get; init; } = string.Empty;

    public string ModuleName { get; init; } = string.Empty;

    // Module capabilities

    public bool SupportsCreate { get; init; }

    public bool SupportsRead { get; init; }

    public bool SupportsUpdate { get; init; }

    public bool SupportsDelete { get; init; }

    public bool SupportsApprove { get; init; }

    // Maximum permissions available to this role

    public bool AllowedCanCreate { get; init; }

    public bool AllowedCanUpdate { get; init; }

    public bool AllowedCanDelete { get; init; }

    public bool AllowedCanRead { get; init; }

    public bool AllowedCanApprove { get; init; }

    // Actual role permissions

    public bool CanCreate { get; init; }

    public bool CanUpdate { get; init; }

    public bool CanDelete { get; init; }

    public bool CanRead { get; init; }

    public bool CanApprove { get; init; }

    // Audit

    public string? CreatedBy { get; init; }

    public DateTime? CreatedUtc { get; init; }

    public string? ModifiedBy { get; init; }

    public DateTime? ModifiedUtc { get; init; }
}