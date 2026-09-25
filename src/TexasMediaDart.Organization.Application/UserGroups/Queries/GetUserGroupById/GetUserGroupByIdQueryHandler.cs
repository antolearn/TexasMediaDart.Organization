using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Queries.GetUserGroupById;

public sealed class GetUserGroupByIdQueryHandler
    : IQueryHandler<GetUserGroupByIdQuery, UserGroupDto?>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public GetUserGroupByIdQueryHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupDto?> HandleAsync(
        GetUserGroupByIdQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.UserGroupId == Guid.Empty)
        {
            throw new ArgumentException(
                "UserGroupId is required.",
                nameof(query.UserGroupId));
        }

        if (query.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(query.OrganizationId));
        }

        return await _userGroupRepository.GetByIdAsync(
            query.UserGroupId,
            query.OrganizationId,
            cancellationToken);
    }
}