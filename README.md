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

### Event stream 

Definition: The event stream feature in Microsoft Fabric offers a centralized place where you to capture, transform and route real-time events to various destinations with a no-code experience. 

New -> more options -> real-time intelligence -> eventstream 

Tutorial: Create an eventstream in Microsoft Fabric - Microsoft Fabric | Microsoft Learn 

### Lakehouse 

Definition: The Microsoft Fabric Lakehouse is a unified data architecture that combines features of data lakes and data warehouses. It integrates structured and unstructured data, providing a flexible platform for storing, managing, and analysing large volumes of information.   

New -> more options -> data engineering -> lakehouse 

Tutorial: Create a lakehouse - Microsoft Fabric | Microsoft Learn 

### KQL 

Definition: The KQL database in Microsoft Fabric is primarily used to store and analyse real-time analytics data. It’s a fully managed Kusto engine that allows queries to be executed using the Kusto Query Language (KQL). You can use the KQL database to store historical data and process streaming data as needed 

New -> more options -> real-time intelligence -> event house 

Tutorial: Create a KQL database - Microsoft Fabric | Microsoft Learn 

## Script deployment and setup in the gateway nodes

These are available scripts to retrieve and process logs from on-premises gateways. These scripts, created by Edgar Cotte, help in managing and processing logs. For more details, you can find them in the GitHub repository: ecotte/rt-gateway-log (github.com). 

Process overview 

The setup-configuration 

script is there to set up the configurations and connect the on-premises gateway to the different endpoints within Fabric (EventStream, Lakehouse, KQL Database, etc.) 

The script will first ask you whether you still need to install the necessary PowerShell Modules needed for Lakehouse connectivity (Az.Accounts, Az.Storage, DataGateway).  

Az.Accounts is a module that manages credentials and common configuration for all Azure modules. The Az.Storage module is a PowerShell module that provides cmdlets for managing and interacting with Azure Storage resources. The DataGateway module is responsible for managing On-premises data gateway and also Power BI data sources. 

 More information about these modules and Az PowerShell can be found here: 

Install Azure PowerShell on Windows | Microsoft Learn 

Sign in to Azure PowerShell interactively | Microsoft Learn 

az account | Microsoft Learn 

az storage | Microsoft Learn 

PowerShell Cmdlets for On-premises data gateway management | Microsoft Learn 

Use Azure service principals with Azure PowerShell | Microsoft Learn 

Once the modules have been set, the script will automatically retrieve the Gateway ID and set up the connections to the event streams and KQL database. A more detailed description of this process and how it’s done can be found in the section Setup_Endpoints_Guide. 

Setup-UpdateConfiguration Script 

This script can be used to update system configurations in response to changes in the setup.  The following parameters can be modified: 

Gateway logs path, default: "C:\\Windows\\ServiceProfiles\\PBIEgwService\\AppData\\Local\\Microsoft\\On-premises data gateway" 

Gateway ID 

Service principal 

Run-GatewayHeartbeat Script:  

The heartbeat logs contain the status of a gateway.  The script will loop and send the logs to the EventStream to be processed in Fabric. 

Run-UploadGatewayLogs Script  

Endpoints setup scripts  

Prerequisites: 

If you run into access errors use: 

powershell -ExecutionPolicy bypass 

Learning Materials 

Topic 

Link(s) 

On-prem data gateway 

What is an on-premises data gateway? | Microsoft Learn 

Fabric 

Get started with Microsoft Fabric - Training | Microsoft Learn 

Implement Real-Time Intelligence with Microsoft Fabric - Training | Microsoft Learn 
 
(Video) Learn the Fundamentals of Microsoft Fabric in 38 minutes 

KQL 

Kusto Query Language (KQL) overview - Azure Data Explorer & Real-Time Analytics | Microsoft Learn 
 

Create a KQL database - Microsoft Fabric | Microsoft Learn 

Lakehouse 

What is a lakehouse? - Microsoft Fabric | Microsoft Learn 

EventStream  

Add and manage eventstream destinations - Microsoft Fabric | Microsoft Learn 
 
Stream real-time events from a custom app to a Microsoft Fabric KQL database - Microsoft Fabric | Microsoft Learn 
 
(Video) Creating your first EVENTSTREAM in Microsoft Fabric 

Service principle 

Demystifying Service Principals - Managed Identities - Azure DevOps Blog (microsoft.com) 

Task Scheduling 

How to Run PowerShell Script on Schedule in Windows (windowsloop.com) 

 

Technical Requirements: 

PowerShell 7+ 

Ensure you have the On-premises data gateway folder in this directory: 

C:\Program Files\On-premises data gateway 

If not, you can download it here: Download Download On-premises data gateway from Official Microsoft Download Center  

You can also run the Install-DataGatewayAuto script.  

If you run into any issues with the config path, you can create your own config folder and file with the following path: .\configs\config.json 

Service Principal: 

To create a service principal using Azure PowerShell, follow these steps: 

Install the Az PowerShell module. 

Connect to your Azure account using the Connect-AzAccount cmdlet. 

Create a service principal with the New-AzADServicePrincipal cmdlet. 

Use Azure service principals with Azure PowerShell | Microsoft Learn 

Useful links on how to create a Service Principal: 

 Create Service Principal in Azure Portal and Assign Permissions | azure-notes (jiasli.github.io) 

Use Azure service principals with Azure PowerShell | Microsoft Learn 

Step 1: Run the setup-configuration script 

The script will ask you whether you want to install the following modules: 

  

******************************************************************* 

Install PowerShell Module Az.Accounts? Needed only for Lakehouse connectivity (Y/N): 

Install PowerShell Module Az.Storage? Needed only for Lakehouse connectivity (Y/N):  

Install PowerShell Module DataGateway? Needed only for Lakehouse connectivity (Y/N): 

 

Type 'y' to install the modules if you don't have them already. 

  

It will then ask whether you want to configure the Heartbeat for the Gateway Reports. Say ' yes' to this. 

You can then configure the Heartbeat, Report, and Verbose Logs intervals.  There is a default value for each of them. You can change these by saying ' no' when prompted and provide the desired interval.  

  

You will then be asked to provide the connection string of the EventStream/EventHub. Provide the connection string from the source of the EventStream/EventHub as we want to pass the logs from the gateway to our KQL database. 

******************************************************************* 

******************************************************************* 

Do you want to configure the Heartbeat for the Gateway Reports? (Y/N): y 

Set Heartbeat Inverval to default 1s? (Y/N): y 

Heartbeat Inverval 1s 

Set Heartbeat EventStream/EventHub connection string: y 

******************************************************************* 

******************************************************************* 

Set Report Inverval to default 5s (Y/N): y 

Log Inverval 5s 

******************************************************************* 

******************************************************************* 

Set Verbose Logs Inverval to default 60s (Y/N): y 

Verbose Log Inverval 60s 

******************************************************************* 

******************************************************************* 

Do you want to configure the EventStream/EventHub for the Gateway Reports? (Y/N): y 

Configure only 1 EventStream? (Y/N): y 

Set EventStream/EventHub connection string: [CONNECTION STRING] 

 

The connection string can be found in the EventStream/EventHub by viewing the keys section of the source you want to connect to (Leave the destination empty for now): 

A screenshot of a computer

Description automatically generated 

The script will then ask whether you want to configure the EventStream/EventHub for the Gateway reports. You can now configure the number of EventStreams you want to configure (default is 1). Similar to setting up the Heartbeat reports, you want to provide the connection string from the source of the EventStream you are connecting to. 

 

******************************************************************* 

Do you want to configure the EventStream/EventHub for the Gateway Reports? (Y/N): y 

Configure only 1 EventStream? (Y/N): y 

Set EventStream/EventHub connection string:  [CONNECTION STRING] 

= 

Once that is all set up, you will have to configure the Service Principal to connect to 	your Lakehouse. You will have to provide the tenant id, app id, and secret text. You can find the tenant and app ID in the overview of the Service Principal you created.  

A screenshot of a computer

Description automatically generated 

The secret text can be created/found in the Certificates & Secrets tab. 

A close-up of a message

Description automatically generated 

******************************************************************* 

******************************************************************* 

Do you want to configure the Service Principal? (Without SP you can´t connect to the Lakehouse) (Y/N): y 

Set the Service Principal Tennat Id: [TENNANT ID] 

Set the Service Principal App Id: [APP ID] 

Set the Service Principal Secret Text: [SECRET TEXT] 

 

Finally, you have to configure the Workspace and Lakehouse you set up earlier. Provide the name of the Workspace and Lakehouse.  

******************************************************************* 

Do you want to configure the Lakehouse upload for the Gateway? (Y/N): y 

Do you want to configure the Lakehouse upload for the Gateway Reports? (Y/N): y 

Do you want to configure the Lakehouse upload for the Gateway Logs? (Y/N): y 

Set the Workspace name: [NAME_WORK_SPACE_LOWERCASE] 

Set the Lakehouse name: [NAME LAKEHOUSE] 

Step 2: Run the Run-GatewayHeartbeat Script 

Run the heartbeat script for a bit so the EventStream can ingest some data. This is needed to configure the output of the EventStream. The output in the terminal whilst running the script should somewhat look like this:  

A screenshot of a computer screen

Description automatically generated 

Step 3: Configure the Heartbeat Eventstream 

Go to the Heartbeat EventStream. When you click on the block in the middle connecting the source and destination, you should be able to see some data in the Data Preview: 

A screenshot of a computer

Description automatically generated 
 

This means that the heartbeat logs have been successfully sent to the EventStream. To process this and send it and store the logs in the KQL database, add a new destination to the EventStream. Select “Event Processing before ingestion” and fill out the form. Select the workspace and the KQL database you want to store the logs in and create a new table for the heartbeat logs. Once you have configured everything, you can save it and exit the menu. The logs will now be properly processed and stored.  

A screenshot of a computer

Description automatically generated 

Step 4: Run the Run-UploadGatewayLogs Script 

Run the UploadGatewayLogs script for a bit so the EventStream can ingest some data. This is needed to configure the output of the EventStream. The output in the terminal whilst running the script should somewhat look like this: 

A screen shot of a computer program

Description automatically generated 

Step 5: Configure the Gateway Logs Eventstream 

Similar to configuring the Heartbeat EventStream, you will need to set up the EventStream destination for gateway logs. However, for gateway logs, it is necessary to create two separate destinations because the logs contain different columns and properties, requiring distinct processing. 

One destination is designated to store the logs of the gateway itself, capturing the operational details and performance metrics. The other destination is intended to store any query logs that the gateway captures, detailing the queries that pass through it. 

It is recommended to store these two types of logs in separate tables due to their differing attributes. This separation ensures clarity and facilitates easier analysis. You can create the two destinations one by one, ensuring the setup matches the configuration shown in the diagram below: 

gw_report_logs_dest: For storing gateway operation logs. 

query_logs_dest: For storing query logs captured by the gateway. 

By setting up the destinations as shown, you can manage and analyze the distinct types of logs more efficiently. 

 
 

Pre-processing gateway logs 

Let’s start by creating the destination for the gateway report logs. To ensure that the logs are stored and processed correctly, you need to open the Event Processor: 
 

The event processor should look like this: 
There are different operations available as you can see in the operations dropdown. You use these operations to pre-process the data before injecting it into the database. Since we want to focus on the gateway reports first, you will want to filter out irrelevant logs first, which are in this case the query logs. You can do so be creating a Filter operation that looks like this: 
 

You then want to create a second filter to filter out the OpenConnectionReports. 

 

Once the logs have been properly filtered, you need to expand the log column as the actual log is inside that column: 
 

The expand feature allows you to retrieve the values inside a list of a column. With the Managefields operation, you can read those values and create separate columns for them as shown in the image below. Select the values you want to keep.  

 
Once you have configured the Managefields operation, you can connect this to the KQL database node, and the data will be pre-processed according to the implemented logic.  
 

Pre-processing query logs 

The query logs are processed similarly as the heartbeat logs. The only difference is that the filters are applied differently.  

 

 

Step 6: Automate the logging process 

Open Task Schedular on Windows and create a “Basic Task”: 

 

Select a trigger got the task. You can just set one for now and edit this later on. 

 

Program/script is the path to your pwsh 7. Make sure it's pwsh 7+ or it won't work!! 

In the arguments, add the full path to either the GW report script or the heartbeat script. 

 

Once the basic task has been created, you can customize it a bit more as the trigger that’s currently in place is not very specific. You can edit the task you created by changing the properties to what works best for you.   
You can also add multiple triggers: 
 

In the Conditions tab, you can also add certain conditions to the triggers. This will allow you to have more control of when triggers can be activated.  

 

The Settings tab will allow you to set up stop conditions as you may not want to run the tasks infinitely. Once this is all set up, the scripts will automatically run based on the conditions you set and upload the gateway logs to the Event Stream.  

 

 

 

Data analysis and visualization (Power BI) 



# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)
