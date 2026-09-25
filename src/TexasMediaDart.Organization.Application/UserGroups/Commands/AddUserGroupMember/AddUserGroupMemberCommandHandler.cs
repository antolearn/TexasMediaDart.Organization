using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.AddUserGroupMember;

public sealed class AddUserGroupMemberCommandHandler
    : ICommandHandler<AddUserGroupMemberCommand, UserGroupMemberCreatedDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public AddUserGroupMemberCommandHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupMemberCreatedDto> HandleAsync(
        AddUserGroupMemberCommand command,
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

        if (string.IsNullOrWhiteSpace(command.CreatedBy))
        {
            throw new ArgumentException(
                "CreatedBy is required.",
                nameof(command.CreatedBy));
        }

        return await _userGroupRepository.AddMemberAsync(
            command.UserGroupId,
            command.OrganizationUserId,
            command.OrganizationId,
            command.CreatedBy.Trim(),
            cancellationToken);
    }
}