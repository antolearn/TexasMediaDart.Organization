using TexasMediaDart.Organization.Application.Common.CQRS;
using TexasMediaDart.Organization.Application.Organizations.Models;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentOrganization;
using TexasMediaDart.Organization.Application.Organizations.Abstractions;
using TexasMediaDart.Organization.Infrastructure.Organizations;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using TexasMediaDart.Organization.Application.Organizations.Commands.CreateOrganization;
using TexasMediaDart.Organization.Api.ExceptionHandling;
using TexasMediaDart.Organization.Api.Extensions;
using TexasMediaDart.Organization.Application.Organizations.Queries.GetCurrentUserModules;
using TexasMediaDart.Organization.Application.Users.Abstractions;
using TexasMediaDart.Organization.Infrastructure.Users;
using TexasMediaDart.Organization.Application.Users.Models;
using TexasMediaDart.Organization.Application.Users.Queries.SearchUsers;
using TexasMediaDart.Organization.Application.Authorization;
using TexasMediaDart.Organization.Application.Organizations.Commands.UpdateOrganization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddScoped<IOrganizationRepository, OrganizationRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();


var jwtIssuer = builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException("Jwt:Issuer is not configured.");

builder.Services.AddScoped<
    IQueryHandler<GetCurrentOrganizationQuery, CurrentOrganizationDto?>,
    GetCurrentOrganizationQueryHandler>();

builder.Services.AddScoped<
    IQueryHandler<
        GetCurrentUserModulesQuery,
        IReadOnlyList<UserModulePermissionDto>>,
    GetCurrentUserModulesQueryHandler>();

builder.Services.AddScoped<
    IQueryHandler<SearchUsersQuery, OrganizationUserSearchResultDto>,
    SearchUsersQueryHandler>();


builder.Services.AddScoped<
    ICommandHandler<CreateOrganizationCommand, CreateOrganizationResultDto>,
    CreateOrganizationCommandHandler>();
builder.Services.AddScoped<
    ICommandHandler<UpdateOrganizationCommand, CurrentOrganizationDto>,
    UpdateOrganizationCommandHandler>();
builder.Services.AddScoped<
    IModuleAuthorizationService,
    ModuleAuthorizationService>();
builder.Services.AddScoped<
    IOrganizationAccessService,
    OrganizationAccessService>();

builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

var jwtAudience = builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException("Jwt:Audience is not configured.");

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key is not configured.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,

            ValidateAudience = true,
            ValidAudience = jwtAudience,

            ValidateLifetime = true,

            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)),

            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

const string CorsPolicy = "FrontendCorsPolicy";

var allowedOrigins =
    builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>()
    ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                // LOCAL development:
                // Allow localhost / 127.0.0.1 on any port.
                if (builder.Environment.IsDevelopment() &&
                    uri.IsLoopback &&
                    (uri.Scheme == Uri.UriSchemeHttp ||
                     uri.Scheme == Uri.UriSchemeHttps))
                {
                    return true;
                }

                // DEV / PROD:
                // Only allow explicitly configured frontend origins.
                return allowedOrigins.Contains(
                    origin,
                    StringComparer.OrdinalIgnoreCase);
            })
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseExceptionHandler();
app.UseCors(CorsPolicy);

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthEndpoints();

app.Run();
