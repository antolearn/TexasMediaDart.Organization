using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.GetUserGroupById;

public sealed record GetUserGroupByIdQuery(
    Guid UserGroupId,
    Guid OrganizationId)
    : IQuery<UserGroupDto?>;