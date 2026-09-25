using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.UserGroups.Commands.CreateUserGroup;
using TexasMediaDart.Organization.Application.UserGroups.Commands.DeleteUserGroup;
using TexasMediaDart.Organization.Application.UserGroups.Commands.UpdateUserGroup;
using TexasMediaDart.Organization.Application.UserGroups.Models;
using TexasMediaDart.Organization.Application.UserGroups.Queries.GetUserGroupById;
using TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroups;
using TexasMediaDart.Organization.Application.UserGroups.Commands.AddUserGroupMember;
using TexasMediaDart.Organization.Application.UserGroups.Commands.RemoveUserGroupMember;
using TexasMediaDart.Organization.Application.UserGroups.Queries.SearchUserGroupMembers;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/user-groups")]
[Authorize]
public sealed class UserGroupsController : ControllerBase
{
    private const string UserGroupsModuleCode = "USER_GROUPS";

    private readonly IOrganizationRepository _organizationRepository;
    private readonly IOrganizationAccessService _organizationAccessService;
    private readonly IModuleAuthorizationService _moduleAuthorizationService;

    private readonly IQueryHandler<
        SearchUserGroupsQuery,
        UserGroupSearchResultDto> _searchUserGroupsHandler;

    private readonly IQueryHandler<
        GetUserGroupByIdQuery,
        UserGroupDto?> _getUserGroupByIdHandler;

    private readonly ICommandHandler<
        CreateUserGroupCommand,
        UserGroupDto> _createUserGroupHandler;

    private readonly ICommandHandler<
        UpdateUserGroupCommand,
        UserGroupDto> _updateUserGroupHandler;

    private readonly ICommandHandler<
        DeleteUserGroupCommand,
        UserGroupDto> _deleteUserGroupHandler;

    private readonly IQueryHandler<
        SearchUserGroupMembersQuery,
        UserGroupMemberSearchResultDto> _searchUserGroupMembersHandler;

    private readonly ICommandHandler<
        AddUserGroupMemberCommand,
        UserGroupMemberCreatedDto> _addUserGroupMemberHandler;

    private readonly ICommandHandler<
        RemoveUserGroupMemberCommand,
        bool> _removeUserGroupMemberHandler;

    public UserGroupsController(
        IOrganizationRepository organizationRepository,
        IOrganizationAccessService organizationAccessService,
        IModuleAuthorizationService moduleAuthorizationService,
        IQueryHandler<
            SearchUserGroupsQuery,
            UserGroupSearchResultDto> searchUserGroupsHandler,
        IQueryHandler<
            GetUserGroupByIdQuery,
            UserGroupDto?> getUserGroupByIdHandler,
        ICommandHandler<
            CreateUserGroupCommand,
            UserGroupDto> createUserGroupHandler,
        ICommandHandler<
            UpdateUserGroupCommand,
            UserGroupDto> updateUserGroupHandler,
        ICommandHandler<
            DeleteUserGroupCommand,
            UserGroupDto> deleteUserGroupHandler,
        IQueryHandler<
            SearchUserGroupMembersQuery,
            UserGroupMemberSearchResultDto> searchUserGroupMembersHandler,
        ICommandHandler<
            AddUserGroupMemberCommand,
            UserGroupMemberCreatedDto> addUserGroupMemberHandler,
        ICommandHandler<
            RemoveUserGroupMemberCommand,
            bool> removeUserGroupMemberHandler)
    {
        _organizationRepository = organizationRepository;
        _organizationAccessService = organizationAccessService;
        _moduleAuthorizationService = moduleAuthorizationService;
        _searchUserGroupsHandler = searchUserGroupsHandler;
        _getUserGroupByIdHandler = getUserGroupByIdHandler;
        _createUserGroupHandler = createUserGroupHandler;
        _updateUserGroupHandler = updateUserGroupHandler;
        _deleteUserGroupHandler = deleteUserGroupHandler;
        _searchUserGroupMembersHandler = searchUserGroupMembersHandler;
        _addUserGroupMemberHandler = addUserGroupMemberHandler;
        _removeUserGroupMemberHandler = removeUserGroupMemberHandler;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(UserGroupSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<UserGroupSearchResultDto>> Search(
        [FromQuery] string? searchText,
        [FromQuery] bool? isActive,
        [FromQuery] bool? isApproved,
        [FromQuery] bool includeDeleted = false,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var query =
            new SearchUserGroupsQuery(
                organization.OrganizationId,
                searchText,
                isActive,
                isApproved,
                includeDeleted,
                pageNumber,
                pageSize);

        var result =
            await _searchUserGroupsHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }

    [HttpGet("{userGroupId:guid}")]
    [ProducesResponseType(
        typeof(UserGroupDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserGroupDto>> GetById(
        Guid userGroupId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var query =
            new GetUserGroupByIdQuery(
                userGroupId,
                organization.OrganizationId);

        var result =
            await _getUserGroupByIdHandler.HandleAsync(
                query,
                cancellationToken);

        if (result is null)
        {
            return NotFound(new
            {
                message =
                    "The user group does not exist in this organization."
            });
        }

        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(UserGroupDto),
        StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserGroupDto>> Create(
        [FromBody] CreateUserGroupRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanCreateAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        if (!TryGetAuthenticatedEmail(out var email))
        {
            return Unauthorized();
        }

        var command =
            new CreateUserGroupCommand(
                organization.OrganizationId,
                request.Name,
                request.Description,
                email);

        var result =
            await _createUserGroupHandler.HandleAsync(
                command,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new
            {
                userGroupId = result.UserGroupId
            },
            result);
    }

    [HttpPut("{userGroupId:guid}")]
    [ProducesResponseType(
        typeof(UserGroupDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserGroupDto>> Update(
        Guid userGroupId,
        [FromBody] UpdateUserGroupRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        if (!TryGetAuthenticatedEmail(out var email))
        {
            return Unauthorized();
        }

        var command =
            new UpdateUserGroupCommand(
                userGroupId,
                organization.OrganizationId,
                request.Name,
                request.Description,
                request.IsActive,
                email);

        var result =
            await _updateUserGroupHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    [HttpDelete("{userGroupId:guid}")]
    [ProducesResponseType(
        typeof(UserGroupDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserGroupDto>> Delete(
        Guid userGroupId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanDeleteAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        if (!TryGetAuthenticatedEmail(out var email))
        {
            return Unauthorized();
        }

        var command =
            new DeleteUserGroupCommand(
                userGroupId,
                organization.OrganizationId,
                email);

        var result =
            await _deleteUserGroupHandler.HandleAsync(
                command,
                cancellationToken);

        return Ok(result);
    }

    [HttpGet("{userGroupId:guid}/members")]
    [ProducesResponseType(
        typeof(UserGroupMemberSearchResultDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserGroupMemberSearchResultDto>> SearchMembers(
        Guid userGroupId,
        [FromQuery] bool? isActive,
        [FromQuery] bool? isApproved,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanReadAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var query =
            new SearchUserGroupMembersQuery(
                userGroupId,
                organization.OrganizationId,
                isActive,
                isApproved,
                pageNumber,
                pageSize);

        var result =
            await _searchUserGroupMembersHandler.HandleAsync(
                query,
                cancellationToken);

        return Ok(result);
    }
    [HttpPost("{userGroupId:guid}/members")]
    [ProducesResponseType(
    typeof(UserGroupMemberCreatedDto),
    StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserGroupMemberCreatedDto>> AddMember(
    Guid userGroupId,
    [FromBody] AddUserGroupMemberRequest request,
    CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        if (!TryGetAuthenticatedEmail(out var email))
        {
            return Unauthorized();
        }

        var command =
            new AddUserGroupMemberCommand(
                userGroupId,
                request.OrganizationUserId,
                organization.OrganizationId,
                email);

        var result =
            await _addUserGroupMemberHandler.HandleAsync(
                command,
                cancellationToken);

        return StatusCode(
            StatusCodes.Status201Created,
            result);
    }
    [HttpDelete(
        "{userGroupId:guid}/members/{organizationUserId:long}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveMember(
        Guid userGroupId,
        long organizationUserId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetIdentityUserId(out var identityUserId))
        {
            return Unauthorized();
        }

        if (!await HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken))
        {
            return Forbid();
        }

        if (!await _moduleAuthorizationService.CanUpdateAsync(
                identityUserId,
                UserGroupsModuleCode,
                cancellationToken))
        {
            return Forbid();
        }

        var organization =
            await _organizationRepository.GetCurrentAsync(
                identityUserId,
                cancellationToken);

        if (organization is null)
        {
            return Forbid();
        }

        var command =
            new RemoveUserGroupMemberCommand(
                userGroupId,
                organizationUserId,
                organization.OrganizationId);

        await _removeUserGroupMemberHandler.HandleAsync(
            command,
            cancellationToken);

        return NoContent();
    }

    private bool TryGetIdentityUserId(
        out Guid identityUserId)
    {
        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        return Guid.TryParse(
            value,
            out identityUserId);
    }

    private bool TryGetAuthenticatedEmail(
        out string email)
    {
        email =
            User.FindFirstValue(
                ClaimTypes.Email)
            ?? User.FindFirstValue("email")
            ?? string.Empty;

        return !string.IsNullOrWhiteSpace(email);
    }

    private async Task<bool> HasActiveOrganizationAsync(
        Guid identityUserId,
        CancellationToken cancellationToken)
    {
        return await _organizationAccessService
            .HasActiveOrganizationAsync(
                identityUserId,
                cancellationToken);
    }
}

public sealed record CreateUserGroupRequest(
    string Name,
    string? Description);

public sealed record UpdateUserGroupRequest(
    string Name,
    string? Description,
    bool IsActive);
public sealed record AddUserGroupMemberRequest(
    long OrganizationUserId);