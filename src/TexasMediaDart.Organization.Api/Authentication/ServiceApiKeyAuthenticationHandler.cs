using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace TexasMediaDart.Organization.Api.Authentication;

public sealed class ServiceApiKeyAuthenticationHandler
    : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly IConfiguration _configuration;

    public ServiceApiKeyAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IConfiguration configuration)
        : base(options, logger, encoder)
    {
        _configuration = configuration;
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var configuredApiKey =
            _configuration[ServiceApiKeyDefaults.ConfigurationKey];

        if (string.IsNullOrWhiteSpace(configuredApiKey))
        {
            return Task.FromResult(
                AuthenticateResult.Fail(
                    "Service API key is not configured."));
        }

        if (!Request.Headers.TryGetValue(
                ServiceApiKeyDefaults.HeaderName,
                out var suppliedApiKey))
        {
            return Task.FromResult(
                AuthenticateResult.NoResult());
        }

        var suppliedApiKeyValue = suppliedApiKey.ToString();

        if (!KeysMatch(
                configuredApiKey,
                suppliedApiKeyValue))
        {
            return Task.FromResult(
                AuthenticateResult.Fail(
                    "Invalid service API key."));
        }

        var claims = new[]
        {
            new Claim(
                ClaimTypes.NameIdentifier,
                "TexasMediaDart.MainApi"),

            new Claim(
                ClaimTypes.Name,
                "TexasMediaDart.MainApi")
        };

        var identity = new ClaimsIdentity(
            claims,
            ServiceApiKeyDefaults.AuthenticationScheme);

        var principal = new ClaimsPrincipal(identity);

        var ticket = new AuthenticationTicket(
            principal,
            ServiceApiKeyDefaults.AuthenticationScheme);

        return Task.FromResult(
            AuthenticateResult.Success(ticket));
    }

    private static bool KeysMatch(
        string expected,
        string actual)
    {
        var expectedHash =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(expected));

        var actualHash =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(actual));

        return CryptographicOperations.FixedTimeEquals(
            expectedHash,
            actualHash);
    }
}