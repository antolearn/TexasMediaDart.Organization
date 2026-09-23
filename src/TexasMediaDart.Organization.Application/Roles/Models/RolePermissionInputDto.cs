namespace TexasMediaDart.Organization.Application.Roles.Models;

public sealed class RolePermissionInputDto
{
    public int ModuleId { get; init; }

    public bool CanCreate { get; init; }

    public bool CanUpdate { get; init; }

    public bool CanDelete { get; init; }

    public bool CanRead { get; init; }

    public bool CanApprove { get; init; }
}