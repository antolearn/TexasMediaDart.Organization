using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Models;
using TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;
using TexasMediaDart.Organization.Api.Models.Users;
using TexasMediaDart.Organization.Application.Users.Queries.GetCandidateIdentityUserIds;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public sealed class UsersController : ControllerBase
{
    private const string UsersModuleCode = "USERS";

    private readonly IOrganizationAccessService _organizationAccessService;

    private readonly IQueryHandler<
        SearchUsersQuery,
        OrganizationUserSearchResultDto> _searchUsersHandler;

    private readonly IQueryHandler<
        GetCandidateIdentityUserIdsQuery,
        IReadOnlyList<Guid>> _getCandidateIdentityUserIdsHandler;

    private readonly IModuleAuthorizationService _moduleAuthorizationService;

    public UsersController(
            IQueryHandler<
                SearchUsersQuery,
                OrganizationUserSearchResultDto> searchUsersHandler,
            IQueryHandler<
                GetCandidateIdentityUserIdsQuery,
                IReadOnlyList<Guid>> getCandidateIdentityUserIdsHandler,
            IModuleAuthorizationService moduleAuthorizationService,
            IOrganizationAccessService organizationAccessService)
        {
            _searchUsersHandler = searchUsersHandler;
            _getCandidateIdentityUserIdsHandler =
                getCandidateIdentityUserIdsHandler;
            _moduleAuthorizationService = moduleAuthorizationService;
            _organizationAccessService = organizationAccessService;
        }

    [HttpGet]
    [ProducesResponseType(
        typeof(OrganizationUserSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Search(
        [FromQuery] Guid? identityUserId = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] bool? isApproved = null,
        [FromQuery] string sortBy = "createdUtc",
        [FromQuery] string sortDirection = "desc",
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                identityUserIdValue,
                out var authenticatedIdentityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var normalizedSortBy =
            sortBy.Trim().ToLowerInvariant();

        var normalizedSortDirection =
            sortDirection.Trim().ToLowerInvariant();

        if (normalizedSortBy != "createdutc")
        {
            return BadRequest(new
            {
                message = "SortBy must be createdUtc."
            });
        }

        if (normalizedSortDirection is not ("asc" or "desc"))
        {
            return BadRequest(new
            {
                message = "SortDirection must be asc or desc."
            });
        }

        if (pageNumber < 1)
        {
            return BadRequest(new
            {
                message =
                    "PageNumber must be greater than or equal to 1."
            });
        }

        if (pageSize < 1 || pageSize > 200)
        {
            return BadRequest(new
            {
                message =
                    "PageSize must be between 1 and 200."
            });
        }

        var hasActiveOrganization =
            await _organizationAccessService.HasActiveOrganizationAsync(
                authenticatedIdentityUserId,
                cancellationToken);

        if (!hasActiveOrganization)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                authenticatedIdentityUserId,
                UsersModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new SearchUsersQuery(
            authenticatedIdentityUserId,
            identityUserId,
            isActive,
            isApproved,
            false,
            Array.Empty<Guid>(),
            normalizedSortBy,
            normalizedSortDirection,
            pageNumber,
            pageSize);
        var result =
            await _searchUsersHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }

    [HttpPost("search-by-identity-ids")]
    [ProducesResponseType(
        typeof(OrganizationUserSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SearchByIdentityIds(
        [FromBody] UserSearchByIdentityIdsRequest request,
        CancellationToken cancellationToken = default)
    {
        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                identityUserIdValue,
                out var authenticatedIdentityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var normalizedSortBy =
            request.SortBy.Trim().ToLowerInvariant();

        var normalizedSortDirection =
            request.SortDirection.Trim().ToLowerInvariant();

        if (normalizedSortBy != "createdutc")
        {
            return BadRequest(new
            {
                message = "SortBy must be createdUtc."
            });
        }

        if (normalizedSortDirection is not ("asc" or "desc"))
        {
            return BadRequest(new
            {
                message = "SortDirection must be asc or desc."
            });
        }

        if (request.PageNumber < 1)
        {
            return BadRequest(new
            {
                message =
                    "PageNumber must be greater than or equal to 1."
            });
        }

        if (request.PageSize < 1 || request.PageSize > 200)
        {
            return BadRequest(new
            {
                message =
                    "PageSize must be between 1 and 200."
            });
        }

        var hasActiveOrganization =
            await _organizationAccessService.HasActiveOrganizationAsync(
                authenticatedIdentityUserId,
                cancellationToken);

        if (!hasActiveOrganization)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                authenticatedIdentityUserId,
                UsersModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new SearchUsersQuery(
            authenticatedIdentityUserId,
            request.IdentityUserId,
            request.IsActive,
            request.IsApproved,
            true,
            request.IdentityUserIds
                .Distinct()
                .ToArray(),
            normalizedSortBy,
            normalizedSortDirection,
            request.PageNumber,
            request.PageSize);

        var result =
            await _searchUsersHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }

    [HttpGet("candidate-identity-ids")]
    [ProducesResponseType(
        typeof(IReadOnlyList<Guid>),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetCandidateIdentityUserIds(
        [FromQuery] Guid? identityUserId = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] bool? isApproved = null,
        CancellationToken cancellationToken = default)
    {
        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(
                identityUserIdValue,
                out var authenticatedIdentityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var hasActiveOrganization =
            await _organizationAccessService.HasActiveOrganizationAsync(
                authenticatedIdentityUserId,
                cancellationToken);

        if (!hasActiveOrganization)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                authenticatedIdentityUserId,
                UsersModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new GetCandidateIdentityUserIdsQuery(
            authenticatedIdentityUserId,
            identityUserId,
            isActive,
            isApproved);

        var result =
            await _getCandidateIdentityUserIdsHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }
}
