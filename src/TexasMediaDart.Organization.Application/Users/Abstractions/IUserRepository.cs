using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Abstractions;

public interface IUserRepository
{
    Task<OrganizationUserSearchResultDto> SearchAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}