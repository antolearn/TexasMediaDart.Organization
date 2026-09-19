namespace TexasMediaDart.Organization.Application.Authorization;

public interface IModuleAuthorizationService
{
    Task<bool> CanReadAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default);

    Task<bool> CanCreateAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default);

    Task<bool> CanUpdateAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default);

    Task<bool> CanDeleteAsync(
        Guid identityUserId,
        string moduleCode,
        CancellationToken cancellationToken = default);
}