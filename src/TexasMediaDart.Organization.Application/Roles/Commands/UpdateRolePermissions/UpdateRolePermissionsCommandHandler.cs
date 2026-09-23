using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Commands.UpdateRolePermissions;

public sealed class UpdateRolePermissionsCommandHandler
    : ICommandHandler<
        UpdateRolePermissionsCommand,
        IReadOnlyList<RolePermissionDto>>
{
    private readonly IRoleRepository _roleRepository;

    public UpdateRolePermissionsCommandHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<IReadOnlyList<RolePermissionDto>> HandleAsync(
        UpdateRolePermissionsCommand command,
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

        if (command.Permissions is null)
        {
            throw new ArgumentNullException(
                nameof(command.Permissions),
                "Permissions are required.");
        }

        if (string.IsNullOrWhiteSpace(command.ModifiedBy))
        {
            throw new ArgumentException(
                "ModifiedBy is required.",
                nameof(command.ModifiedBy));
        }

        return await _roleRepository.UpdatePermissionsAsync(
            command.RoleId,
            command.OrganizationId,
            command.Permissions,
            command.ModifiedBy.Trim(),
            cancellationToken);
    }
}