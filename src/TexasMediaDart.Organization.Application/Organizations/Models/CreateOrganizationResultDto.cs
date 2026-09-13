namespace TexasMediaDart.Organization.Application.Organizations.Models;

public sealed class CreateOrganizationResultDto
{
    public Guid OrganizationId { get; init; }

    public string Name { get; init; } = string.Empty;

    public long OrganizationUserId { get; init; }

    public Guid IdentityUserId { get; init; }

    public Guid RoleId { get; init; }

    public string RoleName { get; init; } = string.Empty;

    public string LicenseCode { get; init; } = string.Empty;

    public string CreatedBy { get; init; } = string.Empty;
}