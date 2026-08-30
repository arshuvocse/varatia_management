Write-Host "Publishing promotionweb project..." -ForegroundColor Cyan
dotnet publish "promotionwebandapi\promotionweb.csproj" -c Release -o "publish_output"

if ($LASTEXITCODE -ne 0) {
    Write-Error "dotnet publish failed!"
    exit 1
}

Write-Host "Applying web.config and required runtime folders..." -ForegroundColor Cyan
Copy-Item "promotionwebandapi\web.config" -Destination "publish_output\web.config" -Force

New-Item -ItemType Directory -Path "publish_output\DataProtectionKeys" -Force | Out-Null
New-Item -ItemType Directory -Path "publish_output\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "publish_output\uploads\profiles" -Force | Out-Null

if (Test-Path "SmartBazar_Publish_Build.zip") {
    Remove-Item "SmartBazar_Publish_Build.zip" -Force
}

Write-Host "Creating SmartBazar_Publish_Build.zip..." -ForegroundColor Cyan
Compress-Archive -Path "publish_output\*" -DestinationPath "SmartBazar_Publish_Build.zip" -Force

$f = Get-Item "SmartBazar_Publish_Build.zip"
$sizeMb = [math]::Round($f.Length / 1MB, 2)
Write-Host "Successfully created: SmartBazar_Publish_Build.zip ($sizeMb MB)" -ForegroundColor Green
