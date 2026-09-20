$connectionString = dotnet user-secrets list `
  --project .\src\TexasMediaDart.Organization.Api\TexasMediaDart.Organization.Api.csproj |
  Where-Object { $_ -like "ConnectionStrings:DefaultConnection*" } |
  ForEach-Object { ($_ -split " = ", 2)[1] }
if ([string]::IsNullOrWhiteSpace($connectionString)) {
    Write-Error "DefaultConnection was not found."
} else {
    Write-Host "DefaultConnection loaded successfully."
}
sqlpackage `
  /Action:Publish `
  /SourceFile:".\database\TexasMediaDart.Organization.Database\bin\Debug\TexasMediaDart.Organization.Database.dacpac" `
  /TargetConnectionString:"$connectionString"