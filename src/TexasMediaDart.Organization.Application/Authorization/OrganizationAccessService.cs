using TexasMediaDart.Organization.Application.Organizations.Abstractions;

namespace TexasMediaDart.Organization.Application.Authorization;

public sealed class OrganizationAccessService
    : IOrganizationAccessService
{
    private readonly IOrganizationRepository _organizationRepository;

    public OrganizationAccessService(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public async Task<bool> HasActiveOrganizationAsync(
        Guid identityUserId,
        CancellationToken cancellationToken = default)
    {
        if (identityUserId == Guid.Empty)
        {
            return false;
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return false;
        }

        return organization.IsActive;
    }
}