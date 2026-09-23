using TexasMediaDart.Organization.Api.ExceptionHandling;
using TexasMediaDart.Organization.Api.Extensions;

var builder = WebApplication.CreateBuilder(args);

// ------------------------------------------------------------
// Framework services
// ------------------------------------------------------------

builder.Services.AddOpenApi();
builder.Services.AddControllers();

// ------------------------------------------------------------
// Application / Infrastructure dependencies
// ------------------------------------------------------------

builder.Services.AddApplicationServices();

// ------------------------------------------------------------
// Problem Details / Global Exception Handling
// ------------------------------------------------------------

builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

// ------------------------------------------------------------
// Authentication / Authorization
// ------------------------------------------------------------

builder.Services.AddJwtAuthentication(
    builder.Configuration);

// ------------------------------------------------------------
// CORS
// ------------------------------------------------------------

builder.Services.AddFrontendCors(
    builder.Configuration,
    builder.Environment);

// ------------------------------------------------------------
// Build application
// ------------------------------------------------------------

var app = builder.Build();

// ------------------------------------------------------------
// Development
// ------------------------------------------------------------

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// ------------------------------------------------------------
// HTTP pipeline
// ------------------------------------------------------------

app.UseExceptionHandler();

app.UseCors(
    CorsExtensions.FrontendCorsPolicy);

app.UseAuthentication();
app.UseAuthorization();

// ------------------------------------------------------------
// Endpoints
// ------------------------------------------------------------

app.MapControllers();
app.MapHealthEndpoints();

app.Run();