namespace TexasMediaDart.Organization.Api.Extensions;

public static class CorsExtensions
{
    public const string FrontendCorsPolicy =
        "FrontendCorsPolicy";

    public static IServiceCollection AddFrontendCors(
        this IServiceCollection services,
        IConfiguration configuration,
        IWebHostEnvironment environment)
    {
        var allowedOrigins =
            configuration
                .GetSection("Cors:AllowedOrigins")
                .Get<string[]>()
            ?? [];

        services.AddCors(options =>
        {
            options.AddPolicy(
                FrontendCorsPolicy,
                policy =>
                {
                    policy
                        .SetIsOriginAllowed(origin =>
                        {
                            if (!Uri.TryCreate(
                                    origin,
                                    UriKind.Absolute,
                                    out var uri))
                            {
                                return false;
                            }

                            // LOCAL development:
                            // Allow localhost / 127.0.0.1
                            // on any port.
                            if (environment.IsDevelopment() &&
                                uri.IsLoopback &&
                                (uri.Scheme == Uri.UriSchemeHttp ||
                                 uri.Scheme == Uri.UriSchemeHttps))
                            {
                                return true;
                            }

                            // DEV / PROD:
                            // Only explicitly configured origins.
                            return allowedOrigins.Contains(
                                origin,
                                StringComparer.OrdinalIgnoreCase);
                        })
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
        });

        return services;
    }
}