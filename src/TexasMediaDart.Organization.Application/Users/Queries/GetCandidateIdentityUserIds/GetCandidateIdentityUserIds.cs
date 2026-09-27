using TexasMediaDart.Organization.Application.Common.CQRS;

namespace TexasMediaDart.Organization.Application.Users.Queries.GetCandidateIdentityUserIds;

public sealed record GetCandidateIdentityUserIdsQuery(
    Guid IdentityUserId,
    Guid? FilterIdentityUserId,
    bool? IsActive,
    bool? IsApproved)
    : IQuery<IReadOnlyList<Guid>>;