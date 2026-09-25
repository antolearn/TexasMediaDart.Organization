namespace TexasMediaDart.Organization.Application.UserGroups.Models;

public sealed class UserGroupMemberCreatedDto
{
    public Guid UserGroupId { get; init; }

    public long OrganizationUserId { get; init; }

    public Guid IdentityUserId { get; init; }

    public string CreatedBy { get; init; } =
        string.Empty;

    public DateTime CreatedUtc { get; init; }
}