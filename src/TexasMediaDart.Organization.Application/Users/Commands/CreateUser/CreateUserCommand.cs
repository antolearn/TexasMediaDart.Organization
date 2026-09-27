using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Users.Models;

namespace TexasMediaDart.Organization.Application.Users.Commands.CreateUser;

public sealed record CreateUserCommand(
    Guid AuthenticatedIdentityUserId,
    Guid IdentityUserId,
    string CreatedBy)
    : ICommand<OrganizationUserDto>;