using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Common.CQRS;

using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;
using TexasMediaDart.Organization.Application.Organizations.Commands.UpdateOrganization;
using TexasMediaDart.Organization.Application.Organizations.Models;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentUserModules;

using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Application.Users.Models;
using TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;

using TexasMediaDart.Organization.Application.Roles.Abstractions;

using TexasMediaDart.Organization.Infrastructure.Organizations;
using TexasMediaDart.Organization.Infrastructure.Users;
using TexasMediaDart.Organization.Infrastructure.Roles;

using TexasMediaDart.Organization.Application.Roles.Models;
using TexasMediaDart.Organization.Application.Roles.Queries.SearchRoles;

using TexasMediaDart.Organization.Application.Roles.Queries.GetRoleById;
using TexasMediaDart.Organization.Application.Roles.Commands.CreateRole;
using TexasMediaDart.Organization.Application.Roles.Commands.UpdateRole;
using TexasMediaDart.Organization.Application.Roles.Commands.DeleteRole;
using TexasMediaDart.Organization.Application.Roles.Queries.GetRolePermissions;
using TexasMediaDart.Organization.Application.Roles.Commands.UpdateRolePermissions;


namespace TexasMediaDart.Organization.Api.Extensions;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services)
    {
        //------------------------------------------------------
        // Repositories
        //------------------------------------------------------

        services.AddScoped<
            IOrganizationRepository,
            OrganizationRepository>();

        services.AddScoped<
            IUserRepository,
            UserRepository>();

        services.AddScoped<
            IRoleRepository,
            RoleRepository>();

        //------------------------------------------------------
        // Authorization
        //------------------------------------------------------

        services.AddScoped<
            IModuleAuthorizationService,
            ModuleAuthorizationService>();

        services.AddScoped<
            IOrganizationAccessService,
            OrganizationAccessService>();

        //------------------------------------------------------
        // Organization Queries
        //------------------------------------------------------

        services.AddScoped<
            IQueryHandler<
                GetCurrentOrganizationQuery,
                CurrentOrganizationDto?>,
            GetCurrentOrganizationQueryHandler>();

        services.AddScoped<
            IQueryHandler<
                GetCurrentUserModulesQuery,
                IReadOnlyList<UserModulePermissionDto>>,
            GetCurrentUserModulesQueryHandler>();

        //------------------------------------------------------
        // Organization Commands
        //------------------------------------------------------

        services.AddScoped<
            ICommandHandler<
                CreateOrganizationCommand,
                CreateOrganizationResultDto>,
            CreateOrganizationCommandHandler>();

        services.AddScoped<
            ICommandHandler<
                UpdateOrganizationCommand,
                CurrentOrganizationDto>,
            UpdateOrganizationCommandHandler>();

        //------------------------------------------------------
        // User Queries
        //------------------------------------------------------

        services.AddScoped<
            IQueryHandler<
                SearchUsersQuery,
                OrganizationUserSearchResultDto>,
            SearchUsersQueryHandler>();

        //------------------------------------------------------
        // Role Queries
        //------------------------------------------------------

        services.AddScoped<
            IQueryHandler<
                SearchRolesQuery,
                RoleSearchResultDto>,
            SearchRolesQueryHandler>();

        services.AddScoped<
            IQueryHandler<
                GetRoleByIdQuery,
                RoleDto?>,
                GetRoleByIdQueryHandler>();

        services.AddScoped<
            IQueryHandler<
                GetRolePermissionsQuery,
                IReadOnlyList<RolePermissionDto>>,
            GetRolePermissionsQueryHandler>();
        //------------------------------------------------------
        // Role Commands
        //------------------------------------------------------

        services.AddScoped<
            ICommandHandler<
                DeleteRoleCommand,
                RoleDto>,
            DeleteRoleCommandHandler>();

        services.AddScoped<
            ICommandHandler<
                UpdateRoleCommand,
                RoleDto>,
            UpdateRoleCommandHandler>();

        services.AddScoped<
            ICommandHandler<
                CreateRoleCommand,
                RoleDto>,
            CreateRoleCommandHandler>();

        services.AddScoped<
            ICommandHandler<
                UpdateRolePermissionsCommand,
                IReadOnlyList<RolePermissionDto>>,
            UpdateRolePermissionsCommandHandler>();

        return services;
    }


}
