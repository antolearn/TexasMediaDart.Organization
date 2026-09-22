using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Commands.UpdateOrganization;

public sealed record UpdateOrganizationCommand(
    string Name,
    bool IsActive,
    Guid IdentityUserId,
    string UserEmail)
    : ICommand<CurrentOrganizationDto>;