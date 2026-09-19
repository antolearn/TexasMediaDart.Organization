namespace TexasMediaDart.Organization.Application.Users.Models;

public sealed class OrganizationUserDto
{
    public long OrganizationUserId { get; init; }

    public Guid OrganizationId { get; init; }

    public Guid IdentityUserId { get; init; }

    public bool IsActive { get; init; }

    public bool IsApproved { get; init; }

    public string CreatedBy { get; init; } = string.Empty;

    public DateTime CreatedUtc { get; init; }

    public string? ModifiedBy { get; init; }

    public DateTime? ModifiedUtc { get; init; }

    public string? ApprovedBy { get; init; }

    public DateTime? ApprovedUtc { get; init; }
}