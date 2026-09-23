using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.CreateRole;

public sealed class CreateRoleCommandHandler
    : ICommandHandler<CreateRoleCommand, RoleDto>
{
    private readonly IRoleRepository _roleRepository;

    public CreateRoleCommandHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<RoleDto> HandleAsync(
        CreateRoleCommand command,
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
                "Role name is required.",
                nameof(command.Name));
        }

        if (string.IsNullOrWhiteSpace(command.CreatedBy))
        {
            throw new ArgumentException(
                "CreatedBy is required.",
                nameof(command.CreatedBy));
        }

        var roleId = Guid.NewGuid();

        return await _roleRepository.CreateAsync(
            roleId,
            command.OrganizationId,
            command.Name.Trim(),
            string.IsNullOrWhiteSpace(command.Description)
                ? null
                : command.Description.Trim(),
            command.CreatedBy.Trim(),
            cancellationToken);
    }
}