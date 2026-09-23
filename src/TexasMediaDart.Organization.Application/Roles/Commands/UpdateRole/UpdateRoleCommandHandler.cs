using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.UpdateRole;

public sealed class UpdateRoleCommandHandler
    : ICommandHandler<UpdateRoleCommand, RoleDto>
{
    private readonly IRoleRepository _roleRepository;

    public UpdateRoleCommandHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<RoleDto> HandleAsync(
        UpdateRoleCommand command,
        CancellationToken cancellationToken = default)
    {
        if (command.RoleId == Guid.Empty)
        {
            throw new ArgumentException(
                "RoleId is required.",
                nameof(command.RoleId));
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
                "Role name is required.",
                nameof(command.Name));
        }

        if (string.IsNullOrWhiteSpace(command.ModifiedBy))
        {
            throw new ArgumentException(
                "ModifiedBy is required.",
                nameof(command.ModifiedBy));
        }

        return await _roleRepository.UpdateAsync(
            command.RoleId,
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