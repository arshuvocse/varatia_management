Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "1. Building Self-Contained (win-x64)..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path "self_contained_publish") { Remove-Item "self_contained_publish" -Recurse -Force }
dotnet publish "promotionwebandapi\promotionweb.csproj" -c Release -r win-x64 --self-contained true -o "self_contained_publish"

$scWebConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <security>
        <requestFiltering>
          <requestLimits maxAllowedContentLength="104857600" />
        </requestFiltering>
      </security>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath=".\promotionweb.exe" arguments="" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="OutOfProcess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
    <system.web>
      <httpRuntime maxRequestLength="102400" executionTimeout="300" />
    </system.web>
  </location>
</configuration>
"@
Set-Content -Path "self_contained_publish\web.config" -Value $scWebConfig -Force

New-Item -ItemType Directory -Path "self_contained_publish\DataProtectionKeys" -Force | Out-Null
New-Item -ItemType Directory -Path "self_contained_publish\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "self_contained_publish\uploads\profiles" -Force | Out-Null

if (Test-Path "SmartBazar_SelfContained_Build.zip") { Remove-Item "SmartBazar_SelfContained_Build.zip" -Force }
Compress-Archive -Path "self_contained_publish\*" -DestinationPath "SmartBazar_SelfContained_Build.zip" -Force
$scF = Get-Item "SmartBazar_SelfContained_Build.zip"
Write-Host "Self-Contained ZIP created: SmartBazar_SelfContained_Build.zip ($([math]::Round($scF.Length/1MB, 2)) MB)" -ForegroundColor Green

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "2. Building Framework-Dependent (net8.0)..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (Test-Path "publish_output") { Remove-Item "publish_output" -Recurse -Force }
dotnet publish "promotionwebandapi\promotionweb.csproj" -c Release -o "publish_output"

$fdWebConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <security>
        <requestFiltering>
          <requestLimits maxAllowedContentLength="104857600" />
        </requestFiltering>
      </security>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" arguments=".\promotionweb.dll" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="OutOfProcess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
    <system.web>
      <httpRuntime maxRequestLength="102400" executionTimeout="300" />
    </system.web>
  </location>
</configuration>
"@
Set-Content -Path "publish_output\web.config" -Value $fdWebConfig -Force

New-Item -ItemType Directory -Path "publish_output\DataProtectionKeys" -Force | Out-Null
New-Item -ItemType Directory -Path "publish_output\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "publish_output\uploads\profiles" -Force | Out-Null

if (Test-Path "SmartBazar_Publish_Build.zip") { Remove-Item "SmartBazar_Publish_Build.zip" -Force }
Compress-Archive -Path "publish_output\*" -DestinationPath "SmartBazar_Publish_Build.zip" -Force
$fdF = Get-Item "SmartBazar_Publish_Build.zip"
Write-Host "Framework-Dependent ZIP created: SmartBazar_Publish_Build.zip ($([math]::Round($fdF.Length/1MB, 2)) MB)" -ForegroundColor Green
