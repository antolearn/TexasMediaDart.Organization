using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Users.Abstractions;

namespace TexasMediaDart.Organization.Application.Users.Queries.GetCandidateIdentityUserIds;

public sealed class GetCandidateIdentityUserIdsQueryHandler
    : IQueryHandler<
        GetCandidateIdentityUserIdsQuery,
        IReadOnlyList<Guid>>
{
    private readonly IOrganizationRepository _organizationRepository;
    private readonly IUserRepository _userRepository;

    public GetCandidateIdentityUserIdsQueryHandler(
        IOrganizationRepository organizationRepository,
        IUserRepository userRepository)
    {
        _organizationRepository = organizationRepository;
        _userRepository = userRepository;
    }

    public async Task<IReadOnlyList<Guid>> HandleAsync(
        GetCandidateIdentityUserIdsQuery query,
        CancellationToken cancellationToken = default)
    {
        var organization =
            await _organizationRepository.GetCurrentAsync(
                query.IdentityUserId,
                cancellationToken);

        if (organization is null)
        {
            throw new InvalidOperationException(
                "The authenticated user does not belong to an organization.");
        }

        return await _userRepository.GetCandidateIdentityUserIdsAsync(
            organization.OrganizationId,
            query.FilterIdentityUserId,
            query.IsActive,
            query.IsApproved,
            cancellationToken);
    }
}