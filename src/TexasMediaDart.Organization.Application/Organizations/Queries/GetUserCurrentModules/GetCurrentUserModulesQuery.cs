using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Models;

namespace TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentUserModules;

public sealed record GetCurrentUserModulesQuery(
    Guid IdentityUserId)
    : IQuery<IReadOnlyList<UserModulePermissionDto>>;