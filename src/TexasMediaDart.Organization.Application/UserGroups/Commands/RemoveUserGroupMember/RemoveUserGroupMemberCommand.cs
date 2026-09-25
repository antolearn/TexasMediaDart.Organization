using TexasMediaDart.Organization.Application.Common.CQRS;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.RemoveUserGroupMember;

public sealed record RemoveUserGroupMemberCommand(
    Guid UserGroupId,
    long OrganizationUserId,
    Guid OrganizationId)
    : ICommand<bool>;