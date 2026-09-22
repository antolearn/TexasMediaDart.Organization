using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Commands.UpdateOrganization;

public sealed class UpdateOrganizationCommandHandler
    : ICommandHandler<UpdateOrganizationCommand, CurrentOrganizationDto>
{
    private readonly IOrganizationRepository _organizationRepository;

    public UpdateOrganizationCommandHandler(
        IOrganizationRepository organizationRepository)
    {
        _organizationRepository = organizationRepository;
    }

    public async Task<CurrentOrganizationDto> HandleAsync(
        UpdateOrganizationCommand command,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(command.Name))
        {
            throw new ArgumentException(
                "Organization name is required.",
                nameof(command.Name));
        }

        var name = command.Name.Trim();

        if (name.Length < 2)
        {
            throw new ArgumentException(
                "Organization name must be at least 2 characters.",
                nameof(command.Name));
        }

        if (name.Length > 200)
        {
            throw new ArgumentException(
                "Organization name cannot exceed 200 characters.",
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

        if (existingOrganization is null)
        {
            throw new InvalidOperationException(
                "No organization is associated with the authenticated user.");
        }

        return await _organizationRepository.UpdateAsync(
            command.IdentityUserId,
            name,
            command.IsActive,
            command.UserEmail.Trim().ToLowerInvariant(),
            cancellationToken);
    }
}