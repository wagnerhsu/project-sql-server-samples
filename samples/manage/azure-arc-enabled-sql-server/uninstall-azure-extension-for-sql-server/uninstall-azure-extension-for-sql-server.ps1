#
# This script provides a scaleable solution to uninstall Azure extension for SQL Server on a specific Arc-enabled server, 
# all Arc-enabled servers in a specific resource group, specific subscription, a list of subscriptions or the entire account.  
#
# You can specfy a single subscription to scan, or provide subscriptions as a .CSV file with the list of IDs. 
# If not specified, all subscriptions your role has access to are scanned. 
#
# The script accepts the following command line parameters:
# 
# -SubId [subscription_id] | [csv_file_name]    (Limit scope to specific subscriptions. Accepts a .csv file with the list of subscriptions.
#                                               If not specified all subscriptions will be scanned)
# -ResourceGroup [resource_goup]                (Limit scope  to a specific resoure group)
# -MachineName [machine_name]                   (Limit scope to a specific machine)
# -All                                          (Uninstall Azure extension on all Arc-enabled servers in all subscriptions you have contributor access to). 
# 
#

param (
    [Parameter (Mandatory=$false)] 
    [string] $SubId, 
    [Parameter (Mandatory= $false)] 
    [string] $ResourceGroup, 
    [Parameter (Mandatory= $false)] 
    [string] $MachineName, 
    [Parameter (Mandatory= $false)]
    [boolean] $All=$false
)

function CheckModule ($m) {

    # This function ensures that the specified module is imported into the session
    # If module is already imported - do nothing

    if (!(Get-Module | Where-Object {$_.Name -eq $m})) {
         # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m 
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m
            }
            else {

                # If module is not imported, not available and not in online gallery then abort
                write-host "Module $m not imported, not available and not in online gallery, exiting."
                EXIT 1
            }
        }
    }
}

#
# Suppress warnings
#
Update-AzConfig -DisplayBreakingChangeWarning $false

# Load required modules
$requiredModules = @(
    "Az.Accounts",
    "Az.ConnectedMachine",
    "Az.ResourceGraph"
)
$requiredModules | Foreach-Object {CheckModule $_}

# Subscriptions to scan

if ($SubId -like "*.csv") {
    $subscriptions = Import-Csv $SubId
}elseif($SubId -ne $null){
    $subscriptions = [PSCustomObject]@{SubscriptionId = $SubId} | Get-AzSubscription 
}elseif($All){
    $subscriptions = Get-AzSubscription
}else {
    Write-Host ([Environment]::NewLine + "-- Parameter missing --")   
    exit 
}

Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

# Scan arc-enabled servers in each subscription 

foreach ($sub in $subscriptions){

    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id  
    }catch {
        write-host "[Environment]::NewLine + Invalid subscription: $($sub.Id)"
        {continue}
    }
   
    $query = "
    resources
    | where type =~ 'microsoft.hybridcompute/machines/extensions'
    | extend extensionPublisher = tostring(properties.publisher), extensionType = tostring(properties.type), provisioningState = tostring(properties.provisioningState)
    | where extensionPublisher =~ 'Microsoft.AzureData'
    | where provisioningState =~ 'Succeeded'
    | parse id with * '/providers/Microsoft.HybridCompute/machines/' machineName '/extensions/' *
    | project machineName, extensionName = name, resourceGroup, location, subscriptionId, extensionPublisher, extensionType, properties
    "
    
    if ($MachineName) {$query += "| where machineName =~ '$($MachineName)'"}     
    if ($ResourceGroup) {$query += "| where resourceGroup =~ '$($ResourceGroup)'"}

    $resources = Search-AzGraph -Query "$($query) | where subscriptionId =~ '$($sub.Id)'"
    foreach ($r in $resources) {

        

        $setID = @{
            MachineName = $r.MachineName        
            ResourceGroup = $r.resourceGroup        
            Name = $r.extensionName        
        }

        Remove-AzConnectedMachineExtension @SetId -NoWait # | Out-Null
        
    } 
}
    
    