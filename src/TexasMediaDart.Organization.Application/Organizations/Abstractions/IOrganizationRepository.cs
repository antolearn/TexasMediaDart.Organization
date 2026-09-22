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

    Task<CurrentOrganizationDto> UpdateAsync(
        Guid identityUserId,
        string name,
        bool isActive,
        string modifiedBy,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserModulePermissionDto>> GetUserModulesAsync(
        Guid identityUserId,
        CancellationToken cancellationToken = default);
}