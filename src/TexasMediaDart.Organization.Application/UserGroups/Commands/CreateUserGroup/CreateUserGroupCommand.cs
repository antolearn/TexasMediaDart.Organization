using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.CreateUserGroup;

public sealed record CreateUserGroupCommand(
    Guid OrganizationId,
    string Name,
    string? Description,
    string CreatedBy)
    : ICommand<UserGroupDto>;