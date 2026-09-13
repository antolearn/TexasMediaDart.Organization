using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;

public sealed record GetCurrentOrganizationQuery(
    Guid IdentityUserId)
    : IQuery<CurrentOrganizationDto?>;