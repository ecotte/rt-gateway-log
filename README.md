# Introduction 
An on-premises data gateway is software that you install in an on-premises network. The gateway facilitates access to data in that network. The current process involves moving data from an on-premises data source through a gateway to various Microsoft cloud services, such as Power BI. On-premises data gateways serve as bridges, facilitating secure data transfer between these endpoints. These gateways enable multiple users to connect to multiple on-premises data sources, making them suitable for complex scenarios where various users need access to different data sources. 

However, managing the traffic through an on-premises data gateway is challenging due to the number of data sources involved. Currently, there is no solution that provides visibility into the logs of all queries passing through a gateway, making it difficult to trace queries back to their respective data sources. Also a challenge that on-premises data gateways often face is effectively leveraging real-time log analytics, leading to high latency and less-than-optimal information, affecting incident response and gateway health monitoring. 

Our proposed solution addresses this issue by centralizing the logs for easier analysis. This will allow for better management and tracking of data traffic through the gateway. 

Using Microsoft Fabric, these logs are centralized in an event stream and processed efficiently through the EventHouse. This centralized data is then available for analysis in Power BI and can support automated response rules via a data activator (pending implementation). 

![image](https://github.com/ecotte/rt-gateway-log/assets/9998133/99054094-ad9f-4494-a622-8e44c3dcbbd0)


This solution uses Microsoft Fabric to address these issues by providing: 

- In-App Configurations  
- PowerShell Setup Configurations 
- Power BI Template  

Benefits include faster incident response, improved gateway health analytics, and streamlined operations, consequently enhancing overall efficiency and reducing downtime. 


# Implementation guide 

## Full process overview 

To implement implement this solution, we have some step to follow. This steps will cover the creation of all the items in the previous architecture and the script in the Gateway Nodes. We can find the following steps needs to be done: 

- Fabric items initial setup
- Script deployment and setup in the gateway nodes
- Report deployment

## Requirements and estimated workloads 

- Powershell 7+
- Microsoft Fabric Capacity of F16 or higher (the capacity size needed will depend on the amount of logs sent and processed by the system)
- Service Principal with Member access to the Workspace and Admin 

## Fabric initial setup 

### Eventstream 

Definition: The event stream feature in Microsoft Fabric offers a centralized place where you to capture, transform and route real-time events to various destinations with a no-code experience. 

New -> more options -> real-time intelligence -> eventstream 

### Lakehouse 

Definition: The Microsoft Fabric Lakehouse is a unified data architecture that combines features of data lakes and data warehouses. It integrates structured and unstructured data, providing a flexible platform for storing, managing, and analysing large volumes of information.   

New -> more options -> data engineering -> lakehouse 

### KQL 

Definition: The KQL database in Microsoft Fabric is primarily used to store and analyse real-time analytics data. It’s a fully managed Kusto engine that allows queries to be executed using the Kusto Query Language (KQL). You can use the KQL database to store historical data and process streaming data as needed 

New -> more options -> real-time intelligence -> event house 

## Script deployment and setup in the gateway nodes

These are available scripts to retrieve and process logs from on-premises gateways. These scripts help in managing and processing logs. 

### The setup-configuration 

This script is there to set up the configurations and connect the on-premises gateway to the different endpoints within Fabric (EventStream, Lakehouse, Eventhouse, etc.) 

The script will first ask you whether you still need to install the necessary PowerShell Modules needed for Lakehouse connectivity (Az.Accounts, Az.Storage, DataGateway).  

Az.Accounts is a module that manages credentials and common configuration for all Azure modules. The Az.Storage module is a PowerShell module that provides cmdlets for managing and interacting with Azure Storage resources. The DataGateway module is responsible for managing On-premises data gateway and also Power BI data sources. 

 More information about these modules and Az PowerShell can be found here: 

- [Install Azure PowerShell on Windows | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-11.6.0&tabs=powershell&pivots=windows-psgallery)
- [Sign in to Azure PowerShell interactively | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/authenticate-interactive?view=azps-12.0.0)
- [az account | Microsoft Learn ](https://learn.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest)
- [az storage | Microsoft Learn ](https://learn.microsoft.com/en-us/cli/azure/storage?view=azure-cli-latest)
- [PowerShell Cmdlets for On-premises data gateway management | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/gateway/overview?view=datagateway-ps)
- [Use Azure service principals with Azure PowerShell | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-11.6.0)

Once the modules have been set, the script will automatically retrieve the Gateway ID and set up the connections to the eventstreams and lakehouse.

### Setup-UpdateConfiguration Script 

This script can be used to update system configurations in response to changes in the setup.  The following parameters can be modified: 

- Gateway logs path, default: "C:\Windows\ServiceProfiles\PBIEgwService\AppData\Local\Microsoft\On-premises data gateway" 
- Gateway ID 
- Service principal 

### Run-GatewayHeartbeat Script:  

The heartbeat logs contain the status of a gateway.  The script will loop and send the logs to the EventStream to be processed in Fabric. 

### Run-UploadGatewayLogs Script  

This is the main script that does the data movement from local to the service. In case of the Report files we can send the files to the eventstream and lakehouse. The log files are sent to the Lakehouse.
