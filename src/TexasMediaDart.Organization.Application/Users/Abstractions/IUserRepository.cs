using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Abstractions;

public interface IUserRepository
{
    Task<OrganizationUserSearchResultDto> SearchAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        bool filterByIdentityUserIds,
        IReadOnlyCollection<Guid> identityUserIds,
        string sortBy,
        string sortDirection,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Guid>> GetCandidateIdentityUserIdsAsync(
        Guid organizationId,
        Guid? identityUserId,
        bool? isActive,
        bool? isApproved,
        CancellationToken cancellationToken = default);

    Task<OrganizationUserDto> CreateAsync(
        Guid organizationId,
        Guid identityUserId,
        string createdBy,
        CancellationToken cancellationToken = default);

    Task<OrganizationUserDto> AcceptInvitationAsync(
        Guid organizationId,
        Guid identityUserId,
        string createdBy,
        CancellationToken cancellationToken = default);
}