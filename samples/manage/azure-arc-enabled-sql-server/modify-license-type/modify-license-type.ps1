#
# This script provides a scaleable solution to set or change the license type on all Azure-connected SQL Servers
# in a specific subscription, a list of subscruiptions or the entire account. By default, it sets the new license  
# type value only on the servers where it is undefined. 
#
# You can specfy a single subscription to scan, or provide subscriptions as a .CSV file with the list of IDs. 
# If not specified, all subscriptions your role has access to are scanned. 
#
# The script accepts the following command line parameters:
# 
# -SubId [subscription_id] | [csv_file_name]    (Accepts a .csv file with the list of subscriptions)
# -LicenceType [license_type_value]             (Specific LT value)
# -All                                          (Optional. Set the new license type value only if undefined)
# 

param (
    [Parameter (Mandatory= $false)] 
    [string] $SubId, 
    [Parameter (Mandatory= $false)]
    [string] $LicenseType="Paid", 
    [Parameter (Mandatory= $false)]
    [string] $SkipServers,
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
}else{
    $subscriptions = Get-AzSubscription
}


Write-Host ([Environment]::NewLine + "-- Scanning subscriptions --")

# Scan arc-enabled servers in each subscription 

foreach ($sub in $subscriptions){

    if ($sub.State -ne "Enabled") {continue}

    try {
        Set-AzContext -SubscriptionId $sub.Id  
    }catch {
        write-host "Invalid subscription: " $sub.Id
        {continue}
    }
   
    $query = "
        resources
        | where type =~ 'microsoft.hybridcompute/machines/extensions'
        | extend extensionPublisher = tostring(properties.publisher), extensionType = tostring(properties.type)
        | where extensionPublisher =~ 'Microsoft.AzureData'
        | parse id with * '/providers/Microsoft.HybridCompute/machines/' machineName '/extensions/' *
        | project machineName, extensionName = name, resourceGroup, location, subscriptionId, extensionPublisher, extensionType, properties
    "
    
    Search-AzGraph -Query $query | ForEach-Object {
            
        $setID = @{
            MachineName = $_.MachineName        
            Name = $_.extensionName        
            ResourceGroup = $_.resourceGroup        
            Location = $_.location        
            SubscriptionId = $_.subscriptionId
            Publisher = $_.extensionPublisher
            ExtensionType = $_.extensionType    
        }
        $getID = @{
            Name = $_.extensionName 
            MachineName = $_.MachineName
            ResourceGroup = $_.resourceGroup
            SubscriptionId = $_.subscriptionId
        }
        $old =  Get-AzConnectedMachineExtension @getID
        $settings = @{}
        foreach( $property in $_.properties.settings.psobject.properties.name ){ $settings[$property] = $_.properties.settings.$property }
        if (-not $all) {
            if (-not $settings.ContainsKey("LicenseType")) { $settings["LicenseType"] = $LicenseType }
        } else {
            $settings["LicenseType"] = $LicenseType
        }
        if ($_.properties.provisioningState -ne "Succeeded") { 
            Write-Warning "Skipping extension on server $($_.machineName) because it's state is $($_.properties.provisioningState)"; 
        } else {
            Set-AzConnectedMachineExtension @setId -Settings $settings -NoWait
            $new =  Get-AzConnectedMachineExtension @getID
        }
    }
}
    
    