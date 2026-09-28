using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TexasMediaDart.Organization.Api.Authentication;
using TexasMediaDart.Organization.Api.Models.UserInvitations;
using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Commands.AcceptInvitationUser;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Api.Controllers;

[ApiController]
[Route("api/internal/user-invitations")]
[Authorize(
    AuthenticationSchemes =
        ServiceApiKeyDefaults.AuthenticationScheme)]
public sealed class InternalUserInvitationsController : ControllerBase
{
    private const string InvitationServiceAuditIdentity =
        "invitation-service@texasdart.local";

    [HttpPost("accept")]
    [ProducesResponseType(
        typeof(OrganizationUserDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<ActionResult<OrganizationUserDto>> AcceptAsync(
        [FromBody] AcceptUserInvitationRequest request,
        [FromServices]
        ICommandHandler<
            AcceptInvitationUserCommand,
            OrganizationUserDto> handler,
        CancellationToken cancellationToken)
    {
        var command = new AcceptInvitationUserCommand(
            request.OrganizationId,
            request.IdentityUserId,
            InvitationServiceAuditIdentity);

        var result = await handler.HandleAsync(
            command,
            cancellationToken);

        return Ok(result);
    }
}