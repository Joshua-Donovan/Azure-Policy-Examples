# What is this?
This is a policy definition that will deny new deployments of webapps that do not fulfil the requirement of having the FTP state configuration locked down to either "FTPS only" or "Disabled".

### Deployment of deployment template example that will be blocked by the policy:
>New-AzResourceGroupDeployment -ResourceGroupName "Policy_Test_Webapp" -TemplateFile ".\deployment_template_FTPS.json" -TemplateParameterObject @{ftpsState="AllAllowed";site_name="mywebapp-withoutFTPs"}

### Deployment of deployment template example that will deploy:
>New-AzResourceGroupDeployment -ResourceGroupName "Policy_Test_Webapp" -TemplateFile ".\deployment_template_FTPS.json" -TemplateParameterObject @{ftpsState="FTPSonly";site_name="mywebapp-withFTPs"}
