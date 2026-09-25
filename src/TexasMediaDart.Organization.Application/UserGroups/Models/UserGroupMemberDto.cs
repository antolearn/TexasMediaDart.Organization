namespace TexasMediaDart.Organization.Application.UserGroups.Models;

public sealed class UserGroupMemberDto
{
    public Guid UserGroupId { get; init; }

    public long OrganizationUserId { get; init; }

    public Guid IdentityUserId { get; init; }

    public bool IsActive { get; init; }

    public bool IsApproved { get; init; }

    public string MembershipCreatedBy { get; init; } =
        string.Empty;

    public DateTime MembershipCreatedUtc { get; init; }
}