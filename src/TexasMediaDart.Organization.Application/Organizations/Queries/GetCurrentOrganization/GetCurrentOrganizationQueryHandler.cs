using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;

public sealed class GetCurrentOrganizationQueryHandler
    : IQueryHandler<GetCurrentOrganizationQuery, CurrentOrganizationDto?>
{
    private readonly IOrganizationRepository _organizationRepository;

    public GetCurrentOrganizationQueryHandler(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public Task<CurrentOrganizationDto?> HandleAsync(
        GetCurrentOrganizationQuery query,
        CancellationToken cancellationToken = default)
    {
        return _organizationRepository.GetCurrentAsync(
            query.IdentityUserId,
            cancellationToken);
    }
}