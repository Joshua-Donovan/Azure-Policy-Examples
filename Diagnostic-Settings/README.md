# This is where breakdown references for Diagnostic Settings policies will live. 

## TODO: Detailed Explination of Azure-Policy-Definition_Detect-Specific-Diagnostic-Settings
## TODO: Detailed Explination of Azure-Policy-Definition_Set_Output_To_Storage_Account.json
### TODO: Match parameter name against existing debug diagnostics name to weed out existing diagnostic settings (bug: wont deploy if existing diagnostic settings of any name is set.)

Select-AzSubscription -SubscriptionId ${SubscriptionId}
New-AzSubscriptionDeployment -Name ${DefinitionName} -Location ${Location} -TemplateUri "https://raw.githubusercontent.com/Joshua-Donovan/Azure-Policy-Examples/main/Diagnostic-Settings/Azure-Policy-Definition_Set_Output_To_Storage_Account.json"


New-AzSubscriptionDeployment -Name SubscriptionDeploymentTest -Location SouthCentralUS -TemplateUri "https://raw.githubusercontent.com/Joshua-Donovan/Azure-Policy-Examples/main/Diagnostic-Settings/Azure-Policy-Definition_Set_Output_To_Storage_Account.json"