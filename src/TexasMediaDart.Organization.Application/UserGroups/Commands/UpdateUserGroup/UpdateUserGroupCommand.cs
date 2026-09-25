using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.UpdateUserGroup;

public sealed record UpdateUserGroupCommand(
    Guid UserGroupId,
    Guid OrganizationId,
    string Name,
    string? Description,
    bool IsActive,
    string ModifiedBy)
    : ICommand<UserGroupDto>;