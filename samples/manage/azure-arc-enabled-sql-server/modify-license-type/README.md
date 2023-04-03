---
services: Azure Arc-enabled SQL Server
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 2/16/2023
---


# Overview

This script allows you to to set or change the license type on all Azure-connected SQL Servers
on a specific resource, in a single resource group, a specific subscription, a list of subscriptions or all subscriptions to which you have access. By default, it sets the specified license type value on the servers where it is undefined. But you can request to set it on all servers in the selected scope.

You can specify a single subscription to scan, or provide a list of subscriptions as a .CSV file.
If not specified, all subscriptions your role has access to are scanned.

# Prerequisites

- You must have at least a *Contributor* role in each subscription you modify.
- The Azure extension for SQL Server is updated to version 1.1.2230.58 or newer.

# Launching the script

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; | **Description** |
|:--|:--|:--|
|-SubId|subscription_id *or* a file_name|Optional: subscription id or a .csv file with the list of subscriptions<sup>1</sup>. If not specified all subscriptions will be scanned|
|-ResourceGroup |resource_group_name|Optional: Limit the scope  to a specific resource group|
|-MachineName |machine_name|Optional: Limit the scope to a specific machine|
|-LicenceType | "Paid", "PAYG" or "LicenseOnly"| Required: Specifies the license type value |
|-All|\$True or \$False (default)|Optional. Set the new license type for all installed extensions. By default the value is set only if license type is undefined.|

<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation
```

## Example 1

The following command will scan all the subscriptions to which the user has access to, and set the license type to "Paid" on all servers where license type is undefined.

```PowerShell
.\modify-license-type.ps1 -LicenseType Paid
```

## Example 2

The following command will scan the subscription `<sub_id>` and set the license type value to "Paid" on all servers.

```PowerShell
.\modify-license-type.ps1 -SubId <sub_id> -LicenseType Paid -All $True
```

## Example 3

The following command will scan resource group <resource_group_name> in the subscription `<sub_id>` and set the license type value to "PAYG" on all servers.

```PowerShell
.\modify-license-type.ps1 -SubId <sub_id> -ResourceGroup <resource_group_name> -LicenseType PAYG -All $True
```

# Running the script using Cloud Shell

This option is recommended because Cloud shell has the Azure PowerShell modules pre-installed and you are automatically authenticated.  Use the following steps to run the script in Cloud Shell.

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to your cloud shell using the following command:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-license-type/modify-license-type.ps1 -o modify-license-type.ps1
    ```

3. Run the script.

    ```console
   .//modify-license-type.ps1 -LicenseType Paid
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.

# Running the script from a PC


Use the following steps to run the script in a PowerShell session on your PC.

1. Copy the script to your current folder:

    ```console
    curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-arc-enabled-sql-server/modify-license-type/modify-license-type.ps1 -o modify-license-type.ps1
    ```

1. Make sure the NuGet package provider is installed:

    ```console
    Set-ExecutionPolicy  -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Install-packageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
    ```

1. Make sure the the Az module is installed. For more information, see [Install the Azure Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-az-ps):

    ```console
    Install-Module Az -Scope CurrentUser -Repository PSGallery -Force
    ```

1. Connect to Azure with an authenticated account using an authentication method of your choice. For more information, see [Connect-AzAccount](https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount).

    ```console
    Connect-AzAccount <parameters>
    ```

1. Run the script using the desired scope.

    ```console
   .//modify-license-type.ps1 -LicenseType Paid
    ```
