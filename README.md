# Introduction 

An on-premises data gateway is software that you install in an on-premises network. The gateway facilitates access to data in that network. The current process involves moving data from an on-premises data source through a gateway to various Microsoft cloud services, such as Power BI. On-premises data gateways serve as bridges, facilitating secure data transfer between these endpoints. These gateways enable multiple users to connect to multiple on-premises data sources, making them suitable for complex scenarios where various users need access to different data sources. 

However, managing the traffic through an on-premises data gateway is challenging due to the number of data sources involved. Currently, there is no solution that provides visibility into the logs of all queries passing through a gateway, making it difficult to trace queries back to their respective data sources. Also a challenge that on-premises data gateways often face is effectively leveraging real-time log analytics, leading to high latency and less-than-optimal information, affecting incident response and gateway health monitoring. 

Our proposed solution addresses this issue by centralizing the logs for easier analysis. This will allow for better management and tracking of data traffic through the gateway. 

Using Microsoft Fabric, these logs are centralized in an event stream and processed efficiently through the Eventhouse. This centralized data is then available for analysis in Power BI and can support automated response rules via a data activator (pending implementation). 

![image](https://github.com/ecotte/rt-gateway-log/assets/9998133/99054094-ad9f-4494-a622-8e44c3dcbbd0)

This solution uses Microsoft Fabric to address these issues by providing: 

- In-App Configurations  
- PowerShell Setup Configurations 
- Power BI Template  

Benefits include faster incident response, improved gateway health analytics, and streamlined operations, consequently enhancing overall efficiency and reducing downtime. 


# Implementation guide 

## Full process overview 

To implement this solution, we have some step to follow. This steps will cover the creation of all the items in the previous architecture and the script in the Gateway Nodes. We can find the following steps needs to be done: 

- Fabric items initial setup
- Script deployment and setup in the gateway nodes
- Connect Fabric Items
- Report deployment

## Requirements and estimated workloads 

- Powershell 7+
- Microsoft Fabric Capacity of F16 or higher (the capacity size needed will depend on the amount of logs sent and processed by the system)
- Service Principal with Member access to the Workspace and Power BI API Permission "Tenant.Read.All" for extracting the Gateway Information

## Fabric initial setup 

### Eventstream 

Definition: The event stream feature in Microsoft Fabric offers a centralized place where you to capture, transform and route real-time events to various destinations with a no-code experience. 

You will need to create 2 Eventstream. 1 for the Heartbeat and another for the reports.

To create an Eventstream go to "New Item -> Eventstream"

Once the Eventstream is created, click on "New Source" and select "Custom App".

<img width="682" alt="image" src="https://github.com/user-attachments/assets/03da6ee2-bd52-49fb-a2e0-cf7a6bd49b8f">

For each Eventstream, go to the "Custom App" source, and select the connection string. It will be used for the setup of the script.

<img width="652" alt="image" src="https://github.com/user-attachments/assets/5532f16b-af1a-430c-b33d-90bc5c256036">


### Lakehouse 

Definition: The Microsoft Fabric Lakehouse is a unified data architecture that combines features of data lakes and data warehouses. It integrates structured and unstructured data, providing a flexible platform for storing, managing, and analysing large volumes of information.   

To create the Lakehouse go to "New Item -> Lakehouse"

Copy the workspace id and Lakehouse id from the URL as shown in the image.

<img width="810" alt="image" src="https://github.com/user-attachments/assets/195f5f40-1f2b-41c0-9138-36e1194f7908">


### Eventhouse 

Definition: The Eventhouse in Microsoft Fabric is primarily used to store and analyse real-time analytics data. It’s a fully managed Kusto engine that allows queries to be executed using the Kusto Query Language (KQL). You can use the KQL database to store historical data and process streaming data as needed 

First create the Eventhouse with "New Item -> Eventhouse"

After creating the Eventhouse, we are going to run the content of the script "[KQL\Setup.kql](https://github.com/ecotte/rt-gateway-log/blob/main/KQL/Setup.kql)" and create the tables and policies.

The data flow is as follow:

![Screenshot 2024-10-10 232530](https://github.com/user-attachments/assets/9c6aa2b4-76f9-4bb5-9168-fa1947e8da04)


## Script deployment and setup in the gateway nodes

These are available scripts to retrieve and process logs from on-premises gateways. These scripts help in managing and processing logs. 

### The setup-configuration 

This script is there to set up the configurations and connect the on-premises gateway to the different endpoints within Fabric (Eventstream, Lakehouse, Eventhouse, etc.) 

The script will first ask you whether you still need to install the necessary PowerShell Modules needed for Lakehouse connectivity (Az.Accounts, Az.Storage, DataGateway).  

Az.Accounts is a module that manages credentials and common configuration for all Azure modules. The Az.Storage module is a PowerShell module that provides cmdlets for managing and interacting with Azure Storage resources. The Data Gateway module is responsible for managing On-premises data gateway and also Power BI data sources. 

 More information about these modules and Az PowerShell can be found here: 

- [Install Azure PowerShell on Windows | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-11.6.0&tabs=powershell&pivots=windows-psgallery)
- [Sign in to Azure PowerShell interactively | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/authenticate-interactive?view=azps-12.0.0)
- [az account | Microsoft Learn ](https://learn.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest)
- [az storage | Microsoft Learn ](https://learn.microsoft.com/en-us/cli/azure/storage?view=azure-cli-latest)
- [PowerShell Cmdlets for On-premises data gateway management | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/gateway/overview?view=datagateway-ps)
- [Use Azure service principals with Azure PowerShell | Microsoft Learn ](https://learn.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-11.6.0)

Once the modules have been set, the script will automatically retrieve the Gateway ID and set up the connections to the Eventstream and Lakehouse.

### Setup-UpdateConfiguration Script 

This script can be used to update system configurations in response to changes in the setup.  The following parameters can be modified: 

- Gateway logs path, default: "C:\Windows\ServiceProfiles\PBIEgwService\AppData\Local\Microsoft\On-premises data gateway" 
- Gateway ID 
- Service principal 

### Run-GatewayHeartbeat Script:  

The heartbeat logs contain the status of a gateway.  The script will loop and send the logs to the Eventstream to be processed in Fabric. 

### Run-UploadGatewayLogs Script  

This is the main script that does the data movement from local to the service. In case of the Report files we can send the files to the Eventstream and Lakehouse. The log files are sent to the Lakehouse.

### Get-DataGatewayInfo

It will get the Gateway Node info, we can run this once per week or even lower rate.

### Schedule the Scripts

We can use the Task Scheduler in Windows to automate the script. You will fin a template of the Task Schedulers in the folder [\TaskSchedulers](https://github.com/ecotte/rt-gateway-log/tree/main/TaskSchedulers)

## Connect Fabric Items

After creating the Fabric items and setting up the scripts, you should start receiving data in the Eventstream, and now we need to connect the Eventstream to the Eventhouse.

### Heartbeat Eventstream

Go to the Heartbeat Eventstream, and select "New Destination -> KQL Database"

Use the "Direct ingestion" options and look for the KQL Database.

<img width="247" alt="image" src="https://github.com/user-attachments/assets/6c6cc88d-ccc7-4cab-be59-5730ad6e8154">

Select the "GatewayHeartbeat" table and name the connector.

<img width="857" alt="image" src="https://github.com/user-attachments/assets/9ea7a949-c9b6-49b2-b204-6ff43a54c0ff">

Once you see some data, click in "Advance" and chose "Existing mapping", and select from the drop down "GatewayHeartbeat_mapping".

<img width="719" alt="image" src="https://github.com/user-attachments/assets/a55f9ef9-ee3e-45d8-84be-28cf22c05ca9">

### Report Eventstream

Go to the Report Eventstream, and select "New Destination -> KQL Database"

Use the "Direct ingestion" options and look for the KQL Database.

<img width="239" alt="image" src="https://github.com/user-attachments/assets/1f51154b-4851-4898-b159-95650affabaf">

Select the "GatewayReport-Raw" table and name the connector.

<img width="716" alt="image" src="https://github.com/user-attachments/assets/4e55e3c2-cd7d-4e1e-81aa-6a4021426533">


Once you see some data, click in "Advance" and chose "Existing mapping", and select from the drop down "GatewayReport-Raw_mapping".

<img width="722" alt="image" src="https://github.com/user-attachments/assets/6e194238-dc3d-4df8-ae43-97f853331608">

## Report Deployment

Use the template in the [\Gateway Monitoring.pbit](https://github.com/ecotte/rt-gateway-log/blob/main/Fabric%20Items/Gateway%20Monitor.pbit) and put the parameters:
-KustoURL: The Query URL found in the Eventhouse
-KustoDB: The name of the KQL DB

<img width="515" alt="image" src="https://github.com/user-attachments/assets/332991ab-1e2b-409e-a953-8ac98eca8a13">

Then load the report and use the credentials with access to the Eventhouse.

You will find the following pages.

### Gateways

Description of the gateway and the indicator if the heartbeat has been received in the last minute.

<img width="1543" alt="image" src="https://github.com/user-attachments/assets/2ed39a53-fb5f-4f9e-91e7-0561006d4883">

### Jobs

A summary of all jobs (Semantic Model refresh, Dataflow Gen1 refresh, Dataflow Gen2 and Paginated Reports) executed in the clusters.

You can filter by the date you want to look into, how many days you want to look back, the cluster name and the node name.

Selecting a Job in the list will allow you to do a "Drill through" to the Job Details.

<img width="1543" alt="image" src="https://github.com/user-attachments/assets/bea3611b-f297-4fec-8a9b-752bf0c8f95c">

### Job Details

The details of the job, where you can find:
- Summary of the queries related to the job
- How many queries has errors, if any
- Data source kinds summary
- Number of queries by node in the cluster for the job
- Service name related to the job (Power BI Datasets (Semantic Models), Power Query Online (Dataflows Gen2), Dataflows and Paginated Reports)
- Workspace ID and Item ID (Dataflows Gen1 don´t provide this information)
- Errors per query, in which node did it happen and the details of the error
- Summary of connections kind and the path
- Query details with the full information of the query

<img width="1508" alt="image" src="https://github.com/user-attachments/assets/424fcc34-185f-41e6-9441-03519eebbf55">


### Queries

General information of all queries that ran in the gateways

<img width="1418" alt="image" src="https://github.com/user-attachments/assets/d15b8bfa-0696-40c2-bba1-e541aabbffe8">

### Running Jobs

Will show only the jobs that are running in the gateways. Selecting a job and going to the details will give you the information on the job and related queries.

<img width="1412" alt="image" src="https://github.com/user-attachments/assets/44144386-1e25-44e9-a9be-7db5bfcef010">

### System Counters

Overview of the system counters report generated by the Gateways.

<img width="1406" alt="image" src="https://github.com/user-attachments/assets/1542c4e3-e06b-4380-9ee5-e38861d2aa9e">

