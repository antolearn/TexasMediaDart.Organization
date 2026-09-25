using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.DeleteUserGroup;

public sealed class DeleteUserGroupCommandHandler
    : ICommandHandler<DeleteUserGroupCommand, UserGroupDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public DeleteUserGroupCommandHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupDto> HandleAsync(
        DeleteUserGroupCommand command,
        CancellationToken cancellationToken = default)
    {
        if (command.UserGroupId == Guid.Empty)
        {
            throw new ArgumentException(
                "UserGroupId is required.",
                nameof(command.UserGroupId));
        }

        if (command.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(command.OrganizationId));
        }

        if (string.IsNullOrWhiteSpace(command.DeletedBy))
        {
            throw new ArgumentException(
                "DeletedBy is required.",
                nameof(command.DeletedBy));
        }

        return await _userGroupRepository.DeleteAsync(
            command.UserGroupId,
            command.OrganizationId,
            command.DeletedBy.Trim(),
            cancellationToken);
    }
}