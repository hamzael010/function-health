
#-------------------------------------------------------------------------
#
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#--------------------------------------------------------------------------
#
# High Availability (HA) Network Virtual Appliance (NVA) Failover Function
#
# This script provides a sample for monitoring HA NVA firewall status and performing
# failover and/or failback if needed.
#
# This script is used as part of an Azure function app called by a Timer Trigger event.  
#
# To configure this function app, the following items must be setup:
#
#   - Provision the pre-requisite Azure Resource Groups, Virtual Networks and Subnets, Network Virtual Appliances
#
#   - Create an Azure timer function app
#
#   - Set the Azure function app settings with credentials
#     SP_PASSWORD, SP_USERNAME, TENANTID, SUBSCRIPTIONID, AZURECLOUD must be added
#     AZURECLOUD = "AzureCloud" or "AzureUSGovernment"
#
#   - Set Firewall VM names and Resource Group in the Azure function app settings
#     VM1Name, VM2Name, FWMONITOR, FW1FQDN, FW1PORT, FW2FQDN, FW2PORT, FWRGNAME, VMTRIES, FWDELAY, FWUDRTAG must be added
#     FWMONITOR = "VMStatus" or "TCPPort" - If using "TCPPort", then also set FW1FQDN, FW2FQDN, FW1PORT and FW2PORT values
#
#   - Set Timer Schedule where positions represent: Seconds - Minutes - Hours - Day - Month - DayofWeek
#     Example:  "*/30 * * * * *" to run on multiples of 30 seconds
#     Example:  "0 */5 * * * *" to run on multiples of 5 minutes on the 0-second mark
#
#--------------------------------------------------------------------------

Write-Output -InputObject "HA NVA timer trigger function executed at:$(Get-Date)"

#--------------------------------------------------------------------------
# Set firewall monitoring variables here
#--------------------------------------------------------------------------

$VM1Name = $env:VM1Name      # Set the Name of the primary NVA firewall
$VM2RGName = $env:VM2RGName     # Set the ResourceGroup that contains FW2


#--------------------------------------------------------------------------
# Code blocks for supporting functions
#--------------------------------------------------------------------------



Function Test-VMStatus ($VM1RGName, $VM1Name) 
 
{
    Set-AzContext -Subscription "b39a8cd3-c59e-4b21-8cad-5ebb50fd5da2" 
  $VMDetail = Get-AzureRmVM -ResourceGroupName $VM1RGName -Name $VM1Name -Status
  foreach ($VMStatus in $VMDetail.Statuses)
  { 
    $Status = $VMStatus.code
      
    if($Status.CompareTo('PowerState/running') -eq 0)
    {
      Return $False
    }
  }
  Return $True  
}


Function Start-Failover 
{
    Set-AzureRmContext -SubscriptionId "8b6bb832-5df3-447a-86b2-b8e2480203f6"
    az network route-table route update  --resource-group azure-function-vmx-rg --route-table-name route-table-vmx --name test --next-hop-ip-address 10.119.12.5 
   
}



