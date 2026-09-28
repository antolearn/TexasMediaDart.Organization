namespace TexasMediaDart.Organization.Api.Models.UserInvitations;

public sealed class AcceptUserInvitationRequest
{
    public Guid OrganizationId { get; init; }

    public Guid IdentityUserId { get; init; }
}