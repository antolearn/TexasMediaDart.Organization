using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.UserGroups.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Commands.CreateUserGroup;

public sealed class CreateUserGroupCommandHandler
    : ICommandHandler<CreateUserGroupCommand, UserGroupDto>
{
    private readonly IUserGroupRepository _userGroupRepository;

    public CreateUserGroupCommandHandler(
        IUserGroupRepository userGroupRepository)
    {
        _userGroupRepository = userGroupRepository;
    }

    public async Task<UserGroupDto> HandleAsync(
        CreateUserGroupCommand command,
        CancellationToken cancellationToken = default)
    {
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

        if (string.IsNullOrWhiteSpace(command.CreatedBy))
        {
            throw new ArgumentException(
                "CreatedBy is required.",
                nameof(command.CreatedBy));
        }

        var userGroupId = Guid.NewGuid();

        return await _userGroupRepository.CreateAsync(
            userGroupId,
            command.OrganizationId,
            command.Name.Trim(),
            string.IsNullOrWhiteSpace(command.Description)
                ? null
                : command.Description.Trim(),
            command.CreatedBy.Trim(),
            cancellationToken);
    }
}