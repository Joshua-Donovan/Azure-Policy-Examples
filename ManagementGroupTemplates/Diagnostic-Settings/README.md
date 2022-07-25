# Example PowerShell Az Module Command for ManagementGroupTemplates\Diagnostic-Settings\Azure-Policy_Set_Output_To_Storage_Account.json
Anything in ${} Needs to be replaced with your environment's information!

Things to Note:
My template has an allow list for locations, see line 64 of the policy template.
Parameter -TemplateUri can be a local address (C:\...etc) or a web address (Https://www...etc)


```
New-AzManagementGroupDeployment -ManagementGroupId "${MyAwesomeManagementGroup}" -Location "${SouthCentralUS}" -TemplateUri "C:\Dev\Azure-Policy-Examples\ManagementGroupTemplates\Diagnostic-Settings\Azure-Policy_Set_Output_To_Storage_Account.json" -targetMG "MyAwesomeManagementGroup" -effect "DeployIfNotExists" -existingDiagnosticsStorageAccountName "${MyStorageAccountName}" -existingDiagnosticsStorageAccountResourceGroup "policy_2207090040000658" -existingDiagnosticsStorageAccountSubscriptionId 9b7e76e6-1c02-4e83-bf8f-7509a3dd1aab -profileName "setbypolicy_SynapseStorageAnalytics" -logsEnabled "True"
```