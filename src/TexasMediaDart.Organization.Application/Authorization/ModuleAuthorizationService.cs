using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Authorization;

public sealed class ModuleAuthorizationService
    : IModuleAuthorizationService
{
    private readonly IOrganizationRepository _organizationRepository;

    public ModuleAuthorizationService(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public async Task<bool> CanReadAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default)
    {
        var module = await GetModuleAsync(
            identityUserId,
            moduleCode,
            cancellationToken);

        return module?.CanRead == true;
    }

    public async Task<bool> CanCreateAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default)
    {
        var module = await GetModuleAsync(
            identityUserId,
            moduleCode,
            cancellationToken);

        return module?.CanCreate == true;
    }

    public async Task<bool> CanUpdateAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default)
    {
        var module = await GetModuleAsync(
            identityUserId,
            moduleCode,
            cancellationToken);

        return module?.CanUpdate == true;
    }

    public async Task<bool> CanDeleteAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default)
    {
        var module = await GetModuleAsync(
            identityUserId,
            moduleCode,
            cancellationToken);

        return module?.CanDelete == true;
    }

    public async Task<bool> CanApproveAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default)
    {
        var module = await GetModuleAsync(
            identityUserId,
            moduleCode,
            cancellationToken);

        return module?.CanApprove == true;
    }

    private async Task<UserModulePermissionDto?> GetModuleAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(moduleCode))
        {
            return null;
        }

        var modules =
            await _organizationRepository.GetUserModulesAsync(
                identityUserId,
                cancellationToken);

        return modules.FirstOrDefault(
            module =>
                string.Equals(
                    module.ModuleCode,
                    moduleCode,
                    StringComparison.OrdinalIgnoreCase));
    }
}