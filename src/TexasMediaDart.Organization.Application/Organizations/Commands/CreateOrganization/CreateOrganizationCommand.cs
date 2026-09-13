using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;

public sealed record CreateOrganizationCommand(
    string Name,
    Guid IdentityUserId,
    string UserEmail)
    : ICommand<CreateOrganizationResultDto>;