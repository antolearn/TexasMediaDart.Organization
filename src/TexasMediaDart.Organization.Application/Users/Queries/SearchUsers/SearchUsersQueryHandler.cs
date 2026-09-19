using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;

public sealed class SearchUsersQueryHandler
    : IQueryHandler<SearchUsersQuery, OrganizationUserSearchResultDto>
{
    private readonly IOrganizationRepository _organizationRepository;
    private readonly IUserRepository _userRepository;

    public SearchUsersQueryHandler(
        IOrganizationRepository organizationRepository,
        IUserRepository userRepository)
    {
        _organizationRepository = organizationRepository;
        _userRepository = userRepository;
    }

    public async Task<OrganizationUserSearchResultDto> HandleAsync(
        SearchUsersQuery query,
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

        return await _userRepository.SearchAsync(
            organization.OrganizationId,
            query.FilterIdentityUserId,
            query.IsActive,
            query.IsApproved,
            query.PageNumber,
            query.PageSize,
            cancellationToken);
    }
}