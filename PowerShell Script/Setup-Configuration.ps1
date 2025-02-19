<# 
.SYNOPSIS
Set Up the Gateway Logs Configuration

.DESCRIPTION
TODO: Add a description

Default Gateway logs path: "C:\\Windows\\ServiceProfiles\\PBIEgwService\\AppData\\Local\\Microsoft\\On-premises data gateway"
C:\Windows\ServiceProfiles\PBIEgwService\AppData\Local\Microsoft\On-premises data gateway

.INFO
 .\Run-UploadGatewayLogs.ps1 .\Config.json
#>

#requires -Version 7

$ErrorActionPreference = "Stop"

Write-Host "*******************************************************************"
Write-Host "Starting Gateway Monitor Configuration"
Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

if ((Read-Host "Install PowerShell Module Az.Accounts? Needed only for Lakehouse connectivity (Y/N)").ToUpper() -eq "Y") {
    Install-Module -Name Az.Accounts -Force
}

if ((Read-Host "Install PowerShell Module Az.Storage? Needed only for Lakehouse connectivity (Y/N)").ToUpper() -eq "Y") {
    Install-Module -Name Az.Storage -Force
}

if ((Read-Host "Install PowerShell Module DataGateway? Needed only for Lakehouse connectivity (Y/N)").ToUpper() -eq "Y") {
    Install-Module -Name DataGateway -Force
}

if ((Read-Host "Install PowerShell Module MicrosoftPowerBIMgmt? Needed only for GatewayInfo (Y/N)").ToUpper() -eq "Y") {
    Install-Module -Name MicrosoftPowerBIMgmt -Force
}

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Set-Location $currentPath

#Gateway Log Upload Config Structure
$GatewayLogUploadConfig = @{
    GatewayId              = ""
    GatewayLogsPath        = @()
    RootPath               = "raw"
    OutputPath             = ".\data"
    HeartbeatEnable        = $false
    HeartbeatInterval      = 1
    ReportSendInterval     = 5
    ReportRetention        = 10
    VerboseLogSendInterval = 600
    ServicePrincipal       = @{
        TennatId   = ""
        AppId      = ""
        SecretText = ""
    }
    EventHubs              = @{
        UploadReports     = $false
        ConnectionStrings = @()
    }
    Lakehouse              = @{
        UploadReports = $false
        UploadLogs    = $false
        WorkspaceName = ""
        LakehouseName = ""        
    }
    ConnectionProperties = @{
        MaximumRetryCount = 3
        RetryIntervalSec = 1
    }
}

$configFile = ".\configs\config.json"

#Set Log Path
Write-Host "Validating log path"

if ((Read-Host "Do you want to configure the Log Path for the Gateway Reports? (Y/N)").ToUpper() -eq "Y") {
    $GatewayPath = Read-Host "Set the Gateway Log folder"
}
else {   
    $GatewayPath = "C:\Windows\ServiceProfiles\PBIEgwService\AppData\Local\Microsoft\On-premises data gateway"
}

if (!(Test-Path $GatewayPath)) {
    do {
        Write-Host "Log folder '$GatewayPath' not found."
        $GatewayPath = Read-Host "Set the Gateway Log folder"
    } while (!(Test-Path $GatewayPath))
}

$GatewayLogUploadConfig.GatewayLogsPath += $GatewayPath 

Write-Host "Default Log folder '$GatewayPath' set."

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"


#Set Gateway Id
Write-Host "Getting Gateway Id"

$reportFile = Get-ChildItem -path $GatewayPath -Recurse  | Where-Object { $_.Name -ilike "*Report_*.log" } | Sort-Object Length | Select-Object -first 1

if (!$reportFile) {
    Write-Host "Cannot find any report ('*Report_*.log') file on '$path' to infer the GatewayId."
    $GatewayLogUploadConfig.GatewayId = Read-Host "Set the Gateway Id Manually"
}
else {
    $gatewayIdFromCSV = Get-Content -path $reportFile.FullName -First 2 | ConvertFrom-Csv | Select-Object -ExpandProperty GatewayObjectId            
    $GatewayLogUploadConfig.GatewayId = $gatewayIdFromCSV  
}

Write-Host "Gateway Id: $($GatewayLogUploadConfig.GatewayId))"

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Set Gateway Heartbeat
if ((Read-Host "Do you want to configure the Heartbeat for the Gateway Reports? (Y/N)").ToUpper() -eq "Y") {

    $GatewayLogUploadConfig.HeartbeatEnable = $true
    $GatewayLogUploadConfig.HeartbeatInterval = 1
    if ((Read-Host "Set Heartbeat Inverval to default $($GatewayLogUploadConfig.HeartbeatInterval)s? (Y/N)").ToUpper() -eq "N") {
        $GatewayLogUploadConfig.HeartbeatInterval = [int](Read-Host "Set the inveval in Seconds")
    }
    Write-Host "Heartbeat Inverval $($GatewayLogUploadConfig.HeartbeatInterval)s"

    $HeartbeatEventHubString = Read-Host "Set Heartbeat EventStream/EventHub connection string"

    $GatewayLogUploadConfig.EventHubs.ConnectionStrings += @{
        Report                   = "Heartbeat"
        EventHubConnectionString = $HeartbeatEventHubString
    }    
}

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Set Log Interval
if ((Read-Host "Set Report Inverval to default $($GatewayLogUploadConfig.ReportSendInterval)s (Y/N)").ToUpper() -eq "N") {
    $GatewayLogUploadConfig.ReportSendInterval = [int](Read-Host "Set the inveval in Seconds")
}
Write-Host "Log Inverval $($GatewayLogUploadConfig.ReportSendInterval)s"

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Set Log Interval
if ((Read-Host "Set Report Retention to default $($GatewayLogUploadConfig.ReportRetention) days (Y/N)").ToUpper() -eq "N") {
    $GatewayLogUploadConfig.ReportRetention = [int](Read-Host "Set the retention in days")
}
Write-Host "Report Retention $($GatewayLogUploadConfig.ReportRetention) days"

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Set Verbose Log Interval
if ((Read-Host "Set Verbose Logs Inverval to default $($GatewayLogUploadConfig.VerboseLogSendInterval)s (Y/N)").ToUpper() -eq "N") {
    $GatewayLogUploadConfig.VerboseLogSendInterval = [int](Read-Host "Set the inveval in Seconds")
}
Write-Host "Verbose Log Inverval $($GatewayLogUploadConfig.VerboseLogSendInterval)s"

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Set EventStream/EventHub for Reports
if ((Read-Host "Do you want to configure the EventStream/EventHub for the Gateway Reports? (Y/N)").ToUpper() -eq "Y") {    

    $GatewayLogUploadConfig.EventHubs.UploadReports = $true


    $ConString = Read-Host "Set EventStream/EventHub connection string"

    $GatewayLogUploadConfig.EventHubs.ConnectionStrings += @{
        Report                   = "Reports"
        EventHubConnectionString = $ConString
    }

}

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Configure Service Principal
if ((Read-Host "Do you want to configure the Service Principal? (Without SP you can´t connect to the Lakehouse) (Y/N)").ToUpper() -eq "Y") {    

    $GatewayLogUploadConfig.ServicePrincipal.TennatId = Read-Host "Set the Service Principal Tennat Id"
    $GatewayLogUploadConfig.ServicePrincipal.AppId = Read-Host "Set the Service Principal App Id"
    $GatewayLogUploadConfig.ServicePrincipal.SecretText = ConvertFrom-SecureString -SecureString (Read-Host "Set the Service Principal Secret Text" -AsSecureString)

    #Configure Lakehouse
    if ((Read-Host "Do you want to configure the Lakehouse upload for the Gateway? (Y/N)").ToUpper() -eq "Y") {    

        if ((Read-Host "Do you want to configure the Lakehouse upload for the Gateway Reports? (Y/N)").ToUpper() -eq "Y") {        
            $GatewayLogUploadConfig.Lakehouse.UploadReports = $true
        }

        if ((Read-Host "Do you want to configure the Lakehouse upload for the Gateway Logs? (Y/N)").ToUpper() -eq "Y") {        
            $GatewayLogUploadConfig.Lakehouse.UploadLogs = $true
        }

        if ($GatewayLogUploadConfig.Lakehouse.UploadReports -or $GatewayLogUploadConfig.Lakehouse.UploadLogs) {
            $GatewayLogUploadConfig.Lakehouse.WorkspaceName = Read-Host "Set the Workspace Id"
            $GatewayLogUploadConfig.Lakehouse.LakehouseName = Read-Host "Set the Lakehouse Id"
            
        }

    }

}

Write-Host "*******************************************************************"
Write-Host "*******************************************************************"

#Test the Service Principal if it´s set
if ($GatewayLogUploadConfig.ServicePrincipal.SecretText) {

    try {
        Write-Host "Testing the Service Principal"    

        Import-Module DataGateway.Profile

        $SecretText = $GatewayLogUploadConfig.ServicePrincipal.SecretText  | ConvertTo-SecureString
        #Test Service Principal
        Connect-DataGatewayServiceAccount -ApplicationId $GatewayLogUploadConfig.ServicePrincipal.AppId -ClientSecret $SecretText -Tenant $GatewayLogUploadConfig.ServicePrincipal.TennatId    
    }
    catch {
        Write-Error "Service Principal Not Valid"
    }
    
}

New-Item -Path (Split-Path $configFile -Parent) -ItemType Directory -Force
    
ConvertTo-Json $GatewayLogUploadConfig -Depth 5 | Out-File $configFile -force -Encoding utf8