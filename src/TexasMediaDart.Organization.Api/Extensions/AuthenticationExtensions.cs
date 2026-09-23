using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace TexasMediaDart.Organization.Api.Extensions;

public static class AuthenticationExtensions
{
    public static IServiceCollection AddJwtAuthentication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var jwtIssuer = configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException(
                "Jwt:Issuer is not configured.");

        var jwtAudience = configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException(
                "Jwt:Audience is not configured.");

        var jwtKey = configuration["Jwt:Key"]
            ?? throw new InvalidOperationException(
                "Jwt:Key is not configured.");

        services
            .AddAuthentication(
                JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters =
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = jwtIssuer,

                        ValidateAudience = true,
                        ValidAudience = jwtAudience,

                        ValidateLifetime = true,

                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey =
                            new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(jwtKey)),

                        ClockSkew = TimeSpan.FromMinutes(1)
                    };
            });

        services.AddAuthorization();

        return services;
    }
}