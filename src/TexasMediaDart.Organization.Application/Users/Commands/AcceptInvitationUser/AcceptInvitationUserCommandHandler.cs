using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Commands.AcceptInvitationUser;

public sealed class AcceptInvitationUserCommandHandler
    : ICommandHandler<AcceptInvitationUserCommand, OrganizationUserDto>
{
    private readonly IUserRepository _userRepository;

    public AcceptInvitationUserCommandHandler(
        IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<OrganizationUserDto> HandleAsync(
        AcceptInvitationUserCommand command,
        CancellationToken cancellationToken = default)
    {
        if (command.OrganizationId == Guid.Empty)
        {
            throw new ArgumentException(
                "OrganizationId is required.",
                nameof(command.OrganizationId));
        }

        if (command.IdentityUserId == Guid.Empty)
        {
            throw new ArgumentException(
                "IdentityUserId is required.",
                nameof(command.IdentityUserId));
        }

        if (string.IsNullOrWhiteSpace(command.CreatedBy))
        {
            throw new ArgumentException(
                "CreatedBy is required.",
                nameof(command.CreatedBy));
        }

        return await _userRepository.AcceptInvitationAsync(
            command.OrganizationId,
            command.IdentityUserId,
            command.CreatedBy.Trim(),
            cancellationToken);
    }
}