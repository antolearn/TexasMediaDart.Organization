namespace TexasMediaDart.Organization.Api.Authentication;

public static class ServiceApiKeyDefaults
{
    public const string AuthenticationScheme = "TexasDartService";

    public const string HeaderName = "X-TexasDart-Service-Key";

    public const string ConfigurationKey =
        "ServiceAuthentication:ApiKey";
}