using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;

using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

using TexasMediaDart.Organization.Application.Roles.Commands.CreateRole;
using TexasMediaDart.Organization.Application.Roles.Commands.UpdateRole;
using TexasMediaDart.Organization.Application.Roles.Models;
using TexasMediaDart.Organization.Application.Roles.Queries.GetRoleById;
using TexasMediaDart.Organization.Application.Roles.Queries.SearchRoles;
using TexasMediaDart.Organization.Application.Roles.Commands.DeleteRole;
using TexasMediaDart.Organization.Application.Roles.Queries.GetRolePermissions;
using TexasMediaDart.Organization.Application.Roles.Commands.UpdateRolePermissions;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/roles")]
[Authorize]
public sealed class RolesController : ControllerBase
{
    private const string RolesModuleCode = "ROLES";

    private readonly IOrganizationRepository _organizationRepository;

    private readonly IOrganizationAccessService _organizationAccessService;

    private readonly IModuleAuthorizationService _moduleAuthorizationService;

    private readonly IQueryHandler<
        SearchRolesQuery,
        RoleSearchResultDto> _searchRolesHandler;

    private readonly IQueryHandler<
        GetRoleByIdQuery,
        RoleDto?> _getRoleByIdHandler;

    private readonly ICommandHandler<
        CreateRoleCommand,
        RoleDto> _createRoleHandler;

    private readonly ICommandHandler<
        UpdateRoleCommand,
        RoleDto> _updateRoleHandler;

    private readonly ICommandHandler<
        DeleteRoleCommand,
        RoleDto> _deleteRoleHandler;

    private readonly IQueryHandler<
        GetRolePermissionsQuery,
        IReadOnlyList<RolePermissionDto>> _getRolePermissionsHandler;
    private readonly ICommandHandler<
    UpdateRolePermissionsCommand,
    IReadOnlyList<RolePermissionDto>> _updateRolePermissionsHandler;

    public RolesController(
        IOrganizationRepository organizationRepository,
        IOrganizationAccessService organizationAccessService,
        IModuleAuthorizationService moduleAuthorizationService,
        IQueryHandler<
            SearchRolesQuery,
            RoleSearchResultDto> searchRolesHandler,
        IQueryHandler<
            GetRoleByIdQuery,
            RoleDto?> getRoleByIdHandler,
        ICommandHandler<
            CreateRoleCommand,
            RoleDto> createRoleHandler,
        ICommandHandler<
            UpdateRoleCommand,
            RoleDto> updateRoleHandler,
        ICommandHandler<
            DeleteRoleCommand,
            RoleDto> deleteRoleHandler,
        IQueryHandler<
            GetRolePermissionsQuery,
            IReadOnlyList<RolePermissionDto>> getRolePermissionsHandler,
        ICommandHandler<
            UpdateRolePermissionsCommand,
            IReadOnlyList<RolePermissionDto>> updateRolePermissionsHandler)
    {
        _organizationRepository = organizationRepository;
        _organizationAccessService = organizationAccessService;
        _moduleAuthorizationService = moduleAuthorizationService;
        _searchRolesHandler = searchRolesHandler;
        _getRoleByIdHandler = getRoleByIdHandler;
        _createRoleHandler = createRoleHandler;
        _updateRoleHandler = updateRoleHandler;
        _deleteRoleHandler = deleteRoleHandler;
        _getRolePermissionsHandler = getRolePermissionsHandler;
        _updateRolePermissionsHandler = updateRolePermissionsHandler;
    }

    // --------------------------------------------------------
    // GET /api/roles
    // --------------------------------------------------------

    [HttpGet]
    [ProducesResponseType(
        typeof(RoleSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Search(
        [FromQuery] string? searchText = null,
        [FromQuery] bool? isSystemRole = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] bool? isApproved = null,
        [FromQuery] bool includeDeleted = false,
        [FromQuery] string? sortBy = null,
        [FromQuery] string? sortDirection = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new SearchRolesQuery(
            organization.OrganizationId,
            searchText,
            isSystemRole,
            isActive,
            isApproved,
            includeDeleted,
            sortBy,
            sortDirection,
            pageNumber,
            pageSize);

        var result =
            await _searchRolesHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }

    // --------------------------------------------------------
    // GET /api/roles/{roleId}
    // --------------------------------------------------------

    [HttpGet("{roleId:guid}")]
    [ProducesResponseType(
        typeof(RoleDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(
        Guid roleId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new GetRoleByIdQuery(
            roleId,
            organization.OrganizationId);

        var result =
            await _getRoleByIdHandler.HandleAsync(
                query,
                cancellationToken);

        if (result is null)
        {
            return NotFound(new
            {
                message = "The requested role was not found."
            });
        }

        return Ok(result);
    }

    // --------------------------------------------------------
    // GET /api/roles/{roleId}/permissions
    // --------------------------------------------------------

    [HttpGet("{roleId:guid}/permissions")]
    [ProducesResponseType(
        typeof(IReadOnlyList<RolePermissionDto>),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPermissions(
        Guid roleId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canRead =
            await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canRead)
        {
            return Forbid();
        }

        var query = new GetRolePermissionsQuery(
            roleId,
            organization.OrganizationId);

        var result =
            await _getRolePermissionsHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }

    // --------------------------------------------------------
    // PUT /api/roles/{roleId}/permissions
    // --------------------------------------------------------

    [HttpPut("{roleId:guid}/permissions")]
    [ProducesResponseType(
        typeof(IReadOnlyList<RolePermissionDto>),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdatePermissions(
        Guid roleId,
        [FromBody] UpdateRolePermissionsRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canUpdate =
            await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canUpdate)
        {
            return Forbid();
        }

        var authenticatedEmail =
            User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");

        if (string.IsNullOrWhiteSpace(authenticatedEmail))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid email address."
            });
        }

        var command = new UpdateRolePermissionsCommand(
            roleId,
            organization.OrganizationId,
            request.Permissions,
            authenticatedEmail);

        var result =
            await _updateRolePermissionsHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    // --------------------------------------------------------
    // POST /api/roles
    // --------------------------------------------------------

    [HttpPost]
    [ProducesResponseType(
        typeof(RoleDto),
        StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(
        [FromBody] CreateRoleRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canCreate =
            await _moduleAuthorizationService.CanCreateAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canCreate)
        {
            return Forbid();
        }

        var authenticatedEmail =
            User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");

        if (string.IsNullOrWhiteSpace(authenticatedEmail))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid email address."
            });
        }

        var command = new CreateRoleCommand(
            organization.OrganizationId,
            request.Name,
            request.Description,
            authenticatedEmail);

        var result =
            await _createRoleHandler.HandleAsync(
                command,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new
            {
                roleId = result.RoleId
            },
            result);
    }

    // --------------------------------------------------------
    // PUT /api/roles/{roleId}
    // --------------------------------------------------------

    [HttpPut("{roleId:guid}")]
    [ProducesResponseType(
        typeof(RoleDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Update(
        Guid roleId,
        [FromBody] UpdateRoleRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canUpdate =
            await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canUpdate)
        {
            return Forbid();
        }

        var authenticatedEmail =
            User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");

        if (string.IsNullOrWhiteSpace(authenticatedEmail))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid email address."
            });
        }

        var command = new UpdateRoleCommand(
            roleId,
            organization.OrganizationId,
            request.Name,
            request.Description,
            request.IsActive,
            authenticatedEmail);

        var result =
            await _updateRoleHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    // --------------------------------------------------------
    // DELETE /api/roles/{roleId}
    // --------------------------------------------------------

    [HttpDelete("{roleId:guid}")]
    [ProducesResponseType(
        typeof(RoleDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(
        Guid roleId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid identity user id."
            });
        }

        var organization =
            await GetCurrentOrganizationAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var canDelete =
            await _moduleAuthorizationService.CanDeleteAsync(
                identityUserId,
                RolesModuleCode,
                cancellationToken);

        if (!canDelete)
        {
            return Forbid();
        }

        var authenticatedEmail =
            User.FindFirstValue(ClaimTypes.Email)
            ?? User.FindFirstValue("email");

        if (string.IsNullOrWhiteSpace(authenticatedEmail))
        {
            return Unauthorized(new
            {
                message =
                    "The authenticated user does not contain a valid email address."
            });
        }

        var command = new DeleteRoleCommand(
            roleId,
            organization.OrganizationId,
            authenticatedEmail);

        var result =
            await _deleteRoleHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    // --------------------------------------------------------
    // Helpers
    // --------------------------------------------------------

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

    private async Task<CurrentOrganizationDto?>
        GetCurrentOrganizationAsync(
            Guid identityUserId,
            CancellationToken cancellationToken)
    {
        var hasActiveOrganization =
            await _organizationAccessService
                .HasActiveOrganizationAsync(
                    identityUserId,
                    cancellationToken);

        if (!hasActiveOrganization)
        {
            return null;
        }

        return await _organizationRepository.GetCurrentAsync(
            identityUserId,
            cancellationToken);
    }
}

// ------------------------------------------------------------
// Request Models
// ------------------------------------------------------------

public sealed record CreateRoleRequest(
    string Name,
    string? Description);

public sealed record UpdateRoleRequest(
    string Name,
    string? Description,
    bool IsActive);

public sealed record UpdateRolePermissionsRequest(
    IReadOnlyCollection<RolePermissionInputDto> Permissions);
