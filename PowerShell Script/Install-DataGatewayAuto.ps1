# This sample helps automate the installation and configuration of the On-premises data gateway using available PowerShell cmdlets. This script helps with silent install of new gateway cluster with one gateway member only. The script also allows addition gateway admins. For information on each PowerShell script visit the help page for individual PowerSHell cmdlets.

# Before begining to install and register a gateway, for connecting to the gateway service, you would need to use the # Connect-DataGatewayServiceAccount. More information documented in the help page of that cmdlet.

Param(
    # Documented on the Install-DataGateway help page
    [string]
    $configFilePath = ".\configs\config.json"
)

$ErrorActionPreference = "stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Set-Location $currentPath

Write-Host "Loading modules"

#import the powershell functions to run the rest of the script
$modulesFolder = "$currentPath\Modules"
Get-Childitem $modulesFolder -Name -Filter "*.psm1" `
| Sort-Object -Property @{ Expression = { if ($_ -eq "Utils.psm1") { " " }else { $_ } } } `
| ForEach-Object {
    $modulePath = "$modulesFolder\$_"
    Unblock-File $modulePath
    Import-Module $modulePath -Force
}

Write-Host "Current Path: $currentPath"

Write-Host "Config Path: $configFilePath"

if (Test-Path $configFilePath) {
    $config = Get-Content $configFilePath | ConvertFrom-Json
}
else {
    throw "Cannot find config file '$configFilePath'"
}

$secureClientSecret =  $config.ServicePrincipal.SecretText | ConvertTo-SecureString
Connect-DataGatewayServiceAccount -ApplicationId $config.ServicePrincipal.AppId -ClientSecret $secureClientSecret -Tenant $config.ServicePrincipal.TennatId

# Thrown an error if not logged in
Get-DataGatewayAccessToken | Out-Null

# Run the gateway installer on the local computer
Install-DataGateway -AcceptConditions