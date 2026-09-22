using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Models;
using TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;

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

    private readonly IModuleAuthorizationService _moduleAuthorizationService;

    public UsersController(
        IQueryHandler<
            SearchUsersQuery,
            OrganizationUserSearchResultDto> searchUsersHandler,
            IModuleAuthorizationService moduleAuthorizationService,
            IOrganizationAccessService organizationAccessService)
    {
        _searchUsersHandler = searchUsersHandler;
        _moduleAuthorizationService = moduleAuthorizationService;
        _organizationAccessService = organizationAccessService;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(OrganizationUserSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Search(
        [FromQuery] Guid? identityUserId = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] bool? isApproved = null,
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
            pageNumber,
            pageSize);

        var result =
            await _searchUsersHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }
}