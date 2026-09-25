using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.RemoveUserGroupMember;

public sealed class RemoveUserGroupMemberCommandHandler
    : ICommandHandler<RemoveUserGroupMemberCommand, bool>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public RemoveUserGroupMemberCommandHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<bool> HandleAsync(
        RemoveUserGroupMemberCommand command,
        CancellationToken cancellationToken = default)
    {
        if (command.UserGroupId == Guid.Empty)
        {
            throw new ArgumentException(
                "UserGroupId is required.",
                nameof(command.UserGroupId));
        }

        if (command.OrganizationUserId <= 0)
        {
            throw new ArgumentException(
                "OrganizationUserId is required.",
                nameof(command.OrganizationUserId));
        }

        if (command.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(command.OrganizationId));
        }

        await _userGroupRepository.RemoveMemberAsync(
            command.UserGroupId,
            command.OrganizationUserId,
            command.OrganizationId,
            cancellationToken);

        return true;
    }
}