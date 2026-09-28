using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Commands.CreateUser;

public sealed class CreateUserCommandHandler
    : ICommandHandler<CreateUserCommand, OrganizationUserDto>
{
    private readonly IOrganizationRepository _organizationRepository;
    private readonly IUserRepository _userRepository;

    public CreateUserCommandHandler(
        IOrganizationRepository organizationRepository,
        IUserRepository userRepository)
    {
        _organizationRepository = organizationRepository;
        _userRepository = userRepository;
    }

    public async Task<OrganizationUserDto> HandleAsync(
        CreateUserCommand command,
        CancellationToken cancellationToken = default)
    {
        if (command.AuthenticatedIdentityUserId == Guid.Empty)
        {
            throw new ArgumentException(
                "AuthenticatedIdentityUserId is required.",
                nameof(command.AuthenticatedIdentityUserId));
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

        var organization =
            await _organizationRepository.GetCurrentAsync(
                command.AuthenticatedIdentityUserId,
                cancellationToken);

        if (organization is null)
        {
            throw new InvalidOperationException(
                "The authenticated user does not belong to an organization.");
        }

        return await _userRepository.CreateAsync(
            organization.OrganizationId,
            command.IdentityUserId,
            command.CreatedBy.Trim(),
            cancellationToken);
    }
}