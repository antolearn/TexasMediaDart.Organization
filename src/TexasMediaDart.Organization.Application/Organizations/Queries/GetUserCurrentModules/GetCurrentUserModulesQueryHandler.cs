using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentUserModules;

public sealed class GetCurrentUserModulesQueryHandler
    : IQueryHandler<
        GetCurrentUserModulesQuery,
        IReadOnlyList<UserModulePermissionDto>>
{
    private readonly IOrganizationRepository _organizationRepository;

    public GetCurrentUserModulesQueryHandler(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public Task<IReadOnlyList<UserModulePermissionDto>> HandleAsync(
        GetCurrentUserModulesQuery query,
        CancellationToken cancellationToken = default)
    {
        return _organizationRepository.GetUserModulesAsync(
            query.IdentityUserId,
            cancellationToken);
    }
}