namespace TexasMediaDart.Organization.Application.UserGroups.Models;

public sealed class UserGroupDto
{
    public Guid UserGroupId { get; init; }

    public Guid OrganizationId { get; init; }

    public string Name { get; init; } = string.Empty;

    public string? Description { get; init; }

    public bool IsActive { get; init; }

    public bool IsDeleted { get; init; }

    public bool IsApproved { get; init; }

    public string CreatedBy { get; init; } = string.Empty;

    public DateTime CreatedUtc { get; init; }

    public string? ModifiedBy { get; init; }

    public DateTime? ModifiedUtc { get; init; }

    public string? ApprovedBy { get; init; }

    public DateTime? ApprovedUtc { get; init; }
}