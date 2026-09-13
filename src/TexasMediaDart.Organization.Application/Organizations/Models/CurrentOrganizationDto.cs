namespace TexasMediaDart.Organization.Application.Organizations.Models;

public sealed class CurrentOrganizationDto
{
    public Guid OrganizationId { get; init; }

    public string Name { get; init; } = string.Empty;

    public bool IsActive { get; init; }

    public long OrganizationUserId { get; init; }

    public Guid IdentityUserId { get; init; }

    public bool UserIsActive { get; init; }

    public bool UserIsApproved { get; init; }

    public string CreatedBy { get; init; } = string.Empty;

    public DateTime CreatedUtc { get; init; }

    public string? ModifiedBy { get; init; }

    public DateTime? ModifiedUtc { get; init; }
}