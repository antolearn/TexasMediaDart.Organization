using TexasMediaDart.Organization.Application.UserGroups.Models;

namespace TexasMediaDart.Organization.Application.UserGroups.Abstractions;

public interface IUserGroupRepository
{
    Task<UserGroupSearchResultDto> SearchAsync(
        Guid organizationId,
        string? searchText,
        bool? isActive,
        bool? isApproved,
        bool includeDeleted,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<UserGroupDto?> GetByIdAsync(
        Guid userGroupId,
        Guid organizationId,
        CancellationToken cancellationToken = default);

    Task<UserGroupDto> CreateAsync(
        Guid userGroupId,
        Guid organizationId,
        string name,
        string? description,
        string createdBy,
        CancellationToken cancellationToken = default);

    Task<UserGroupDto> UpdateAsync(
        Guid userGroupId,
        Guid organizationId,
        string name,
        string? description,
        bool isActive,
        string modifiedBy,
        CancellationToken cancellationToken = default);

    Task<UserGroupDto> DeleteAsync(
        Guid userGroupId,
        Guid organizationId,
        string deletedBy,
        CancellationToken cancellationToken = default);
    Task<UserGroupMemberSearchResultDto> SearchMembersAsync(
    Guid userGroupId,
    Guid organizationId,
    bool? isActive,
    bool? isApproved,
    int pageNumber,
    int pageSize,
    CancellationToken cancellationToken = default);

    Task<UserGroupMemberCreatedDto> AddMemberAsync(
        Guid userGroupId,
        long organizationUserId,
        Guid organizationId,
        string createdBy,
        CancellationToken cancellationToken = default);

    Task RemoveMemberAsync(
        Guid userGroupId,
        long organizationUserId,
        Guid organizationId,
        CancellationToken cancellationToken = default);
}