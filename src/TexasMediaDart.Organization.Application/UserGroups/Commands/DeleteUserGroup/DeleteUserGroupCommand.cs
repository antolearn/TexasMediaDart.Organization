using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.DeleteUserGroup;

public sealed record DeleteUserGroupCommand(
    Guid UserGroupId,
    Guid OrganizationId,
    string DeletedBy)
    : ICommand<UserGroupDto>;