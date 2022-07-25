# Example PowerShell Az Module Command for ManagementGroupTemplates\Diagnostic-Settings\Azure-Policy_Set_Output_To_Storage_Account.json
Anything in ${} Needs to be replaced with your environment's information!

Things to Note:
My template has an allow list for locations, see line 64 of the policy template.
Parameter -TemplateUri can be a local address (C:\...etc) or a web address (Https://www...etc)

```
New-AzManagementGroupDeployment -ManagementGroupId "${Management Group Name}" -Location "${Location for Assignment / Managed Identity}" -TemplateUri "https://raw.githubusercontent.com/Joshua-Donovan/Azure-Policy-Examples/main/ManagementGroupTemplates/Diagnostic-Settings/Azure-Policy_Set_Output_To_Storage_Account.json" -targetMG "${management group name}" -effect "DeployIfNotExists" -existingDiagnosticsStorageAccountName "${Destination Storage Account Name}" -existingDiagnosticsStorageAccountResourceGroup "${Destination Storage Account Resource Group}" -existingDiagnosticsStorageAccountSubscriptionId ${Destination Storage Account Subscription Id} -profileName "${Diagnostics Settings Name/Label}" -logCategoriesToEnable @("SynapseRbacOperations","GatewayApiRequests","BuiltinSqlReqsEnded","IntegrationPipelineRuns","IntegrationActivityRuns","IntegrationTriggerRuns")
```
### You can select individual log categories if desired, but this selects them all for Synapse. 