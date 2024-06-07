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
