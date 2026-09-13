using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Abstractions;

public interface IOrganizationRepository
{
    Task<CurrentOrganizationDto?> GetCurrentAsync(
        Guid identityUserId,
        CancellationToken cancellationToken = default);

    Task<CreateOrganizationResultDto> CreateAsync(
        Guid organizationId,
        string name,
        Guid identityUserId,
        string userEmail,
        CancellationToken cancellationToken = default);
}