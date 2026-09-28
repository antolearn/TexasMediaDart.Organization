using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Commands.AcceptInvitationUser;

public sealed record AcceptInvitationUserCommand(
    Guid OrganizationId,
    Guid IdentityUserId,
    string CreatedBy)
    : ICommand<OrganizationUserDto>;