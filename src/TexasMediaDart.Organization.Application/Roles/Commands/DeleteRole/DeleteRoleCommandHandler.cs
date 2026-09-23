using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.DeleteRole;

public sealed class DeleteRoleCommandHandler
    : ICommandHandler<DeleteRoleCommand, RoleDto>
{
    private readonly IRoleRepository _roleRepository;

    public DeleteRoleCommandHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<RoleDto> HandleAsync(
        DeleteRoleCommand command,
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

        if (string.IsNullOrWhiteSpace(command.DeletedBy))
        {
            throw new ArgumentException(
                "DeletedBy is required.",
                nameof(command.DeletedBy));
        }

        return await _roleRepository.DeleteAsync(
            command.RoleId,
            command.OrganizationId,
            command.DeletedBy.Trim(),
            cancellationToken);
    }
}