using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.UpdateUserGroup;

public sealed class UpdateUserGroupCommandHandler
    : ICommandHandler<UpdateUserGroupCommand, UserGroupDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public UpdateUserGroupCommandHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupDto> HandleAsync(
        UpdateUserGroupCommand command,
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

        if (string.IsNullOrWhiteSpace(command.Name))
        {
            throw new ArgumentException(
                "User group name is required.",
                nameof(command.Name));
        }

        if (string.IsNullOrWhiteSpace(command.ModifiedBy))
        {
            throw new ArgumentException(
                "ModifiedBy is required.",
                nameof(command.ModifiedBy));
        }

        return await _userGroupRepository.UpdateAsync(
            command.UserGroupId,
            command.OrganizationId,
            command.Name.Trim(),
            string.IsNullOrWhiteSpace(command.Description)
                ? null
                : command.Description.Trim(),
            command.IsActive,
            command.ModifiedBy.Trim(),
            cancellationToken);
    }
}