using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Common.Exceptions;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;

public sealed class CreateOrganizationCommandHandler
    : ICommandHandler<CreateOrganizationCommand, CreateOrganizationResultDto>
{
    private readonly IOrganizationRepository _organizationRepository;

    public CreateOrganizationCommandHandler(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public async Task<CreateOrganizationResultDto> HandleAsync(
        CreateOrganizationCommand command,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(command.Name))
        {
            throw new ArgumentException(
                "Organization name is required.",
                nameof(command.Name));
        }

        if (command.IdentityUserId == Guid.Empty)
        {
            throw new ArgumentException(
                "Identity user id is required.",
                nameof(command.IdentityUserId));
        }

        if (string.IsNullOrWhiteSpace(command.UserEmail))
        {
            throw new ArgumentException(
                "User email is required.",
                nameof(command.UserEmail));
        }
        var existingOrganization =
            await _organizationRepository.GetCurrentAsync(
                command.IdentityUserId,
                cancellationToken);

        if (existingOrganization is not null)
        {
            throw new ConflictException(
                "The authenticated user already belongs to an organization.");
        }

        var organizationId = Guid.NewGuid();

        return await _organizationRepository.CreateAsync(
            organizationId,
            command.Name.Trim(),
            command.IdentityUserId,
            command.UserEmail.Trim().ToLowerInvariant(),
            cancellationToken);
    }
}