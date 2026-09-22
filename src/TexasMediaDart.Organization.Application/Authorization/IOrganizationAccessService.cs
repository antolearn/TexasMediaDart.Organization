namespace TexasMediaDart.Organization.Application.Authorization;

public interface IOrganizationAccessService
{
    Task<bool> HasActiveOrganizationAsync(
        Guid identityUserId,
        CancellationToken cancellationToken = default);
}