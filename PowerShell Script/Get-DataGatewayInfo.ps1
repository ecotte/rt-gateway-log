# This sample helps automate the installation and configuration of the On-premises data gateway using available PowerShell cmdlets. This script helps with silent install of new gateway cluster with one gateway member only. The script also allows addition gateway admins. For information on each PowerShell script visit the help page for individual PowerSHell cmdlets.

# Before begining to install and register a gateway, for connecting to the gateway service, you would need to use the # Connect-DataGatewayServiceAccount. More information documented in the help page of that cmdlet.

#requires -Version 7 -Modules MicrosoftPowerBIMgmt, JoinModule

param(
    [string]
    $configFilePath = ".\configs\Config.json",
    [string]
    $logFolder = ".\logs\"
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

try {

    $secureClientSecret = $config.ServicePrincipal.SecretText | ConvertTo-SecureString
    $servicePrincipal = New-Object PSCredential -ArgumentList $Config.ServicePrincipal.AppId, $secureClientSecret 
    Connect-PowerBIServiceAccount -Environment 'Public' -ServicePrincipal -Credential $servicePrincipal -Tenant $Config.ServicePrincipal.TennatId

    $gateways = Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v2.0/myorg/gatewayClusters" | ConvertFrom-Json

    $computerInfor = Get-ComputerInfo | 
        Select-Object @{ Name = "machine"; Expression = { $_.CsName } },
            @{ Name = "osName"; Expression = { $_.OsName } },
            @{ Name = "osVersion"; Expression = { $_.OsVersion } },
            @{ Name = "cores"; Expression = { $_.CsNumberOfProcessors } },
            @{ Name = "logicalCores"; Expression = { $_.CsNumberOfLogicalProcessors } },
            @{ Name = "memoryGb"; Expression = { $_.CsTotalPhysicalMemory / 1Gb } }

    $gatewayObject = $gateways.value | 
        Select-Object @{Name = "clusterId"; Expression = { $_.id } }, `
            @{Name = "clusterName"; Expression = { $_.name } }, `
            @{Name = "type"; Expression = { $_.type } }, `
            @{Name = "cloudDatasourceRefresh"; Expression = { $_.options.CloudDatasourceRefresh } }, `
            @{Name = "customConnectors"; Expression = { $_.options.CustomConnectors } }, `
            @{Name = "memberGateways"; Expression = { $_.memberGateways | Select-Object * -ExcludeProperty clusterId, publicKey } } |
        Select-Object * -ExpandProperty memberGateways -ExcludeProperty memberGateways |
        Select-Object @{Name = "clusterId"; Expression = { $_.clusterId } }, `
            @{Name = "clusterName"; Expression = { $_.clusterName } }, `
            @{Name = "type"; Expression = { $_.type } }, `
            @{Name = "cloudDatasourceRefresh"; Expression = { $_.cloudDatasourceRefresh } }, `
            @{Name = "customConnectors"; Expression = { $_.customConnectors } }, `
            @{Name = "version"; Expression = { $_.version } }, `
            @{Name = "status"; Expression = { $_.status } }, `
            @{Name = "versionStatus"; Expression = { $_.versionStatus } }, `
            @{Name = "contactInformation"; Expression = { ($_.annotation | ConvertFrom-Json).gatewayContactInformation } }, `
            @{Name = "machine"; Expression = { ($_.annotation | ConvertFrom-Json).gatewayMachine } }, `
            @{Name = "nodeId"; Expression = { $_.id } } |
        Join-Object -RightObject $computerInfor -On 'machine'

    $eventStreamConnection = ($config.EventHubs.ConnectionStrings | Where-Object { $_.Report -eq "Reports" }).EventHubConnectionString

    if ($eventStreamConnection){
        $body = @{
            logType = "GatewayNodeInfo"
            log     = @($gatewayObject)
            logDate = [datetime]::UtcNow
        } | ConvertTo-Json -Depth 5

        Add-MsgEventHub -connectionString $eventStreamConnection -msg $body
    }

}
catch {    
    $ex = $_.Exception   
    $ErrorDate = [datetime]::UtcNow     
    Write-Error "Error on UploadGatewayLogs - $ex" -ErrorAction Continue     
    Out-File  -FilePath "$($logFolder)GatewayMonitoring.log" -InputObject "[Error] $ErrorDate; $ex" -Force -Append
}   