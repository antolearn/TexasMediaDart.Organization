using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Roles.Abstractions;
using TexasMediaDart.Organization.Application.Roles.Models;

namespace TexasMediaDart.Organization.Application.Roles.Queries.GetRoleById;

public sealed class GetRoleByIdQueryHandler
    : IQueryHandler<GetRoleByIdQuery, RoleDto?>
{
    private readonly IRoleRepository _roleRepository;

    public GetRoleByIdQueryHandler(
        IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    public async Task<RoleDto?> HandleAsync(
        GetRoleByIdQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.RoleId == Guid.Empty)
        {
            throw new ArgumentException(
                "RoleId is required.",
                nameof(query.RoleId));
        }

        if (query.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(query.OrganizationId));
        }

        return await _roleRepository.GetByIdAsync(
            query.RoleId,
            query.OrganizationId,
            cancellationToken);
    }
}