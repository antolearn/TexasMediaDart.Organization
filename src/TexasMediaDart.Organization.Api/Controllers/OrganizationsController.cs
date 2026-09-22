using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;
using TexasMediaDart.Organization.Application.Organizations.Commands.UpdateOrganization;
using TexasMediaDart.Organization.Application.Organizations.Models;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentUserModules;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class OrganizationsController : ControllerBase
{
    private const string OrganizationModuleCode = "ORGANIZATION";

    private readonly IOrganizationAccessService _organizationAccessService;

    private readonly IQueryHandler<
        GetCurrentOrganizationQuery,
        CurrentOrganizationDto?> _getCurrentOrganizationHandler;

    private readonly ICommandHandler<
        CreateOrganizationCommand,
        CreateOrganizationResultDto> _createOrganizationHandler;

    private readonly ICommandHandler<
        UpdateOrganizationCommand,
        CurrentOrganizationDto> _updateOrganizationHandler;

    private readonly IQueryHandler<
        GetCurrentUserModulesQuery,
        IReadOnlyList<UserModulePermissionDto>> _getCurrentUserModulesHandler;

    private readonly IModuleAuthorizationService _moduleAuthorizationService;

    public OrganizationsController(
        IQueryHandler<
            GetCurrentOrganizationQuery,
            CurrentOrganizationDto?> getCurrentOrganizationHandler,
        ICommandHandler<
            CreateOrganizationCommand,
            CreateOrganizationResultDto> createOrganizationHandler,
        ICommandHandler<
            UpdateOrganizationCommand,
            CurrentOrganizationDto> updateOrganizationHandler,
        IQueryHandler<
            GetCurrentUserModulesQuery,
            IReadOnlyList<UserModulePermissionDto>> getCurrentUserModulesHandler,
        IModuleAuthorizationService moduleAuthorizationService,
        IOrganizationAccessService organizationAccessService)
    {
        _getCurrentOrganizationHandler = getCurrentOrganizationHandler;
        _createOrganizationHandler = createOrganizationHandler;
        _updateOrganizationHandler = updateOrganizationHandler;
        _getCurrentUserModulesHandler = getCurrentUserModulesHandler;
        _moduleAuthorizationService = moduleAuthorizationService;
        _organizationAccessService = organizationAccessService;
    }

    // ------------------------------------------------------------
    // GET: /api/organizations/current
    //
    // IMPORTANT:
    // This endpoint must remain accessible for an inactive
    // organization. The frontend uses IsActive to determine whether
    // the user should be routed to the deactivated organization page.
    // ------------------------------------------------------------
    [HttpGet("current")]
    [ProducesResponseType(
        typeof(CurrentOrganizationDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrent(
        CancellationToken cancellationToken)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var query =
            new GetCurrentOrganizationQuery(identityUserId);

        var organization =
            await _getCurrentOrganizationHandler.HandleAsync(
                query,
                cancellationToken);

        if (organization is null)
        {
            return NotFound(new
            {
                message =
                    "No organization is associated with the authenticated user."
            });
        }

        return Ok(organization);
    }

    // ------------------------------------------------------------
    // POST: /api/organizations
    // ------------------------------------------------------------
    [HttpPost]
    [ProducesResponseType(
        typeof(CreateOrganizationResultDto),
        StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Create(
        [FromBody] CreateOrganizationRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new
            {
                message = "Organization name is required."
            });
        }

        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var email = GetUserEmail();

        if (string.IsNullOrWhiteSpace(email))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain an email address."
            });
        }

        var command =
            new CreateOrganizationCommand(
                request.Name,
                identityUserId,
                email);

        var result =
            await _createOrganizationHandler.HandleAsync(
                command,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetCurrent),
            null,
            result);
    }

    // ------------------------------------------------------------
    // PUT: /api/organizations/current
    //
    // Updating an organization requires:
    // 1. Valid authenticated user
    // 2. Active organization
    // 3. ORGANIZATION update permission
    // ------------------------------------------------------------
    [HttpPut("current")]
    [ProducesResponseType(
        typeof(CurrentOrganizationDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateCurrent(
        [FromBody] UpdateOrganizationRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var email = GetUserEmail();

        if (string.IsNullOrWhiteSpace(email))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain an email address."
            });
        }

        var hasActiveOrganization =
            await _organizationAccessService.HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (!hasActiveOrganization)
        {
            return Forbid();
        }

        var canUpdate =
            await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                OrganizationModuleCode,
                cancellationToken);

        if (!canUpdate)
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new
            {
                message = "Organization name is required."
            });
        }

        var command =
            new UpdateOrganizationCommand(
                request.Name,
                request.IsActive,
                identityUserId,
                email);

        var result =
            await _updateOrganizationHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    // ------------------------------------------------------------
    // GET: /api/organizations/current/modules
    //
    // Module permissions are only available when the organization
    // is active.
    // ------------------------------------------------------------
    [HttpGet("current/modules")]
    [ProducesResponseType(
        typeof(IReadOnlyList<UserModulePermissionDto>),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetCurrentUserModules(
        CancellationToken cancellationToken)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var hasActiveOrganization =
            await _organizationAccessService.HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (!hasActiveOrganization)
        {
            return Forbid();
        }

        var query =
            new GetCurrentUserModulesQuery(identityUserId);

        var modules =
            await _getCurrentUserModulesHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(modules);
    }

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------
    private bool TryGetIdentityUserId(
        out Guid identityUserId)
    {
        var identityUserIdValue =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        return Guid.TryParse(
            identityUserIdValue,
            out identityUserId);
    }

    private string? GetUserEmail()
    {
        return User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");
    }
}

public sealed class CreateOrganizationRequest
{
    public string Name { get; init; } = string.Empty;
}

public sealed class UpdateOrganizationRequest
{
    public string Name { get; init; } = string.Empty;

    public bool IsActive { get; init; }
}