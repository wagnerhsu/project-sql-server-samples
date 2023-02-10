---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 2/09/2023
---


# Overview


This script allows you to to set or change the license type on all Azure-connected SQL Servers
in a specific subscription, a list of subscriptions or the entire account. By default, it sets the specified license type value on the servers where it is undefined. But you can request to set it on all servers in scope.  

You can specify a single subscription to scan, or provide a list of subscriptions as a .CSV file. 
If not specified, all subscriptions your role has access to are scanned. 


# Required permissions

You must be at least a *Contributor* of each subscription you modify.  

# Launching the script 

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|-SubId|subscription_id *or* a file_name|Optional: subscription id or a .csv file with the list of subscriptions<sup>1</sup>|
|-LicenceType | "Paid" (default), "PAYG" or "LicenseOnly"| Specifies the license type value |
|-All|\$True or \$False (default)|Optional: Set the new license type value only if undefined|

<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation 
```
## Example 1

The following command will scan all the subscriptions to which the user has access to and set the license type to "PAYG".

```PowerShell
.\update-license-type.ps1 -LicenseType "PAYG" -All
```

## Example 2

The following command will scan the subscription `<sub_id>` and set the license type value to "Paid" on the servers where it is undefined.

```PowerShell
.\update-license-type.ps1 -SubId <sub_id> -LicenseType "Paid"
```

# Running the script using Cloud Shell

Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-license-type/modify-license-type.ps1 -o /modify-license-type.ps1
    ```

3. Run the script.  

    ```console
   .//modify-license-type.ps1 -LicenseType "Paid"
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

