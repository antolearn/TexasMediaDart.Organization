using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.AddUserGroupMember;

public sealed record AddUserGroupMemberCommand(
    Guid UserGroupId,
    long OrganizationUserId,
    Guid OrganizationId,
    string CreatedBy)
    : ICommand<UserGroupMemberCreatedDto>;