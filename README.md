# Introduction 

An on-premises data gateway is software that you install in an on-premises network. The gateway facilitates access to data in that network. The current process involves moving data from an on-premises data source through a gateway to various Microsoft cloud services, such as Power BI. On-premises data gateways serve as bridges, facilitating secure data transfer between these endpoints. These gateways enable multiple users to connect to multiple on-premises data sources, making them suitable for complex scenarios where various users need access to different data sources. 

However, managing the traffic through an on-premises data gateway is challenging due to the number of data sources involved. Currently, there is no solution that provides visibility into the logs of all queries passing through a gateway, making it difficult to trace queries back to their respective data sources. Also a challenge that on-premises data gateways often face is effectively leveraging real-time log analytics, leading to high latency and less-than-optimal information, affecting incident response and gateway health monitoring. 

Our proposed solution addresses this issue by centralizing the logs for easier analysis. This will allow for better management and tracking of data traffic through the gateway. 

Using Microsoft Fabric, these logs are centralized in an event stream and processed efficiently through the Eventhouse. This centralized data is then available for analysis in Power BI and can support automated response rules via a data activator (pending implementation). 

![image](https://github.com/ecotte/rt-gateway-log/blob/main/Images/01%20-%20Gateway%20Monitoring%20Architecture.png)

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

<img width="682" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/02%20-%20New%20Eventstream.png">

For each Eventstream, go to the "Custom App" source, and select the connection string. It will be used for the setup of the script.

<img width="652" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/03%20-%20Custom%20App%20Eventstream.png">


### Lakehouse 

Definition: The Microsoft Fabric Lakehouse is a unified data architecture that combines features of data lakes and data warehouses. It integrates structured and unstructured data, providing a flexible platform for storing, managing, and analysing large volumes of information.   

To create the Lakehouse go to "New Item -> Lakehouse"

Copy the workspace id and Lakehouse id from the URL as shown in the image.

<img width="810" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/04%20-%20Lakehouse.png">


### Eventhouse 

Definition: The Eventhouse in Microsoft Fabric is primarily used to store and analyse real-time analytics data. It’s a fully managed Kusto engine that allows queries to be executed using the Kusto Query Language (KQL). You can use the KQL database to store historical data and process streaming data as needed 

First create the Eventhouse with "New Item -> Eventhouse"

After creating the Eventhouse, we are going to run the content of the script "[KQL\Setup.kql](https://github.com/ecotte/rt-gateway-log/blob/main/KQL/Setup.kql)" and create the tables and policies.

The data flow is as follow:

![image](https://github.com/ecotte/rt-gateway-log/blob/main/Images/05%20-%20Gateway%20Report%20Data%20Logic.png)


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

<img width="247" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/06%20-%20Connect%20to%20KQL%20Database.png">

Select the "GatewayHeartbeat" table and name the connector.

<img width="857" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/07%20-%20Select%20Eventhouse%20Table.png">

Once you see some data, click in "Advance" and chose "Existing mapping", and select from the drop down "GatewayHeartbeat_mapping".

<img width="719" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/08%20-%20Select%20Mapping.png">

### Report Eventstream

Go to the Report Eventstream, and select "New Destination -> KQL Database"

Use the "Direct ingestion" options and look for the KQL Database.

<img width="239" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/09%20-%20Connect%20to%20KQL%20Database%20Report.png">

Select the "GatewayReport-Raw" table and name the connector.

<img width="716" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/10%20-%20Select%20Eventhouse%20Table%20Report.png">


Once you see some data, click in "Advance" and chose "Existing mapping", and select from the drop down "GatewayReport-Raw_mapping".

<img width="722" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/12%20-%20Select%20Mapping%20Report.png">

## Report Deployment

Use the template in the [\Gateway Monitoring.pbit](https://github.com/ecotte/rt-gateway-log/blob/main/Fabric%20Items/Gateway%20Monitor.pbit) and put the parameters:
-KustoURL: The Query URL found in the Eventhouse
-KustoDB: The name of the KQL DB

<img width="515" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/11%20-%20PBIT%20Parameters.png">

Then load the report and use the credentials with access to the Eventhouse.

You will find the following pages.

### Gateways

Description of the gateway and the indicator if the heartbeat has been received in the last minute.

<img width="1543" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/13%20-%20Report%20Gateway%20Information.png">

### Jobs

A summary of all jobs (Semantic Model refresh, Dataflow Gen1 refresh, Dataflow Gen2 and Paginated Reports) executed in the clusters.

You can filter by the date you want to look into, how many days you want to look back, the cluster name and the node name.

Selecting a Job in the list will allow you to do a "Drill through" to the Job Details.

<img width="1543" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/14%20-%20Report%20Jobs.png">

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

<img width="1508" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/15%20-%20Report%20Job%20Details.png">


### Queries

General information of all queries that ran in the gateways

<img width="1418" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/16%20-%20Report%20Queries.png">

### Running Jobs

Will show only the jobs that are running in the gateways. Selecting a job and going to the details will give you the information on the job and related queries.

<img width="1412" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/17%20-%20Report%20Running%20Jobs.png">

### System Counters

Overview of the system counters report generated by the Gateways.

<img width="1406" alt="image" src="https://github.com/ecotte/rt-gateway-log/blob/main/Images/18%20-%20Report%20System%20Information.png">

