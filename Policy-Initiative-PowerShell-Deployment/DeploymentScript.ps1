$subscription = "" # Your Subscription Id
$ResourceGroupName = "" # Your RG Name
$ManagementGroupName = "" # Your Management Group name
$ManagementGroupDeploymentName = "" # What you want to name your Management Group deployment

$PolicyDefinitionJSONPath = "" # Path to your policy Definition
$PolicySetDefinitionJSON = "" # Path to your Policy Set Definition file, also where your parameters for your policy definitions live

$PolicyDefinitionName = "" # The name of your Policy Definition being deployed to the Management Group !IMPORTANT! that this name matches what is in your PolicySetDefinition.json file.
$PolicySetDefinitionName = "" # Your Policy Set Definition Name
$PolicyInitiativeName = "" # What you want to name your Initiative Assignment

$Location = "" # What Azure locaiton would you like to use? eastus, centralus, southcentralus ...etc

$ValidationMaxLoop = 2 # How many times do you want the propigation checks to loop

$templateParams = @{
    "existingDiagnosticsStorageAccountName"           = ""; # Your Logging storage account Name
    "existingDiagnosticsStorageAccountResourceGroup"  = ""; # Your Logging storage account Resource Group
    "existingDiagnosticsStorageAccountSubscriptionId" = ""; # Your Logging storage account Subscription
    "policyDefinitionName"                            = "$($PolicyDefinitionName)"; 
} 

# Deploy Policy Definition (You can choose to loop this for more definition deployments for your policy set)
$PolicyDefinition = New-AzManagementGroupDeployment -ManagementGroupId $ManagementGroupName -Location $Location -TemplateFile $PolicyDefinitionJSONPath -TemplateParameterObject $templateParams -Name $ManagementGroupDeploymentName
Write-Host $PolicyDefinition.Id

# Wait for Policy Definition to Propigate
$DefinitionExists = $null
$ValidationLoop = 0
Do {
    if ($PolicyDefinition.ProvisioningState -notlike "Succeeded") {
        Write-Error -Message "Policy Definition did not deploy succesfully."
        Return;
    }
    if ($ValidationLoop -ge $ValidationMaxLoop) {
        Write-Error -Message "Timed out checking for if the Policy Definition Exists"
        Return;
    }
    Start-Sleep -Seconds 5
    Try {
        $DefinitionExists = Get-AzPolicyDefinition -Id "/providers/Microsoft.Management/managementGroups/$($ManagementGroupName)/providers/Microsoft.Authorization/policyDefinitions/$($PolicyDefinitionName)" -ErrorAction Stop
    }
    Catch {}
    $ValidationLoop++
} until (!([String]::IsNullOrEmpty($DefinitionExists)))

# Deploy Policy Set Definition for the Initiative
$InitiativePolicySetDefinition = New-AzPolicySetDefinition -Name $PolicySetDefinitionName -PolicyDefinition $PolicySetDefinitionJSON -WarningAction SilentlyContinue
Write-Host $InitiativePolicySetDefinition.ResourceId

# Wait for Policy Set Definition to Propigate
$DefinitionExists = $null
$ValidationLoop = 0
Do {
    if ([String]::IsNullOrEmpty($InitiativePolicySetDefinition.ResourceId)) {
        Write-Error -Message "Policy Set Definition did not deploy succesfully."
        Return;
    }
    if ($ValidationLoop -ge $ValidationMaxLoop) {
        Write-Error -Message "Timed out checking for if the Policy Definition Exists"
        Return;
    }
    Start-Sleep -Seconds 5
    Try {
        $DefinitionExists = Get-AzPolicySetDefinition -Id $InitiativePolicySetDefinition.ResourceId -ErrorAction Stop
    }
    Catch {}
    $ValidationLoop++
} until (!([String]::IsNullOrEmpty($DefinitionExists)))

# When assigning using a -PolicySetDefinition it is an Initiative
$Assignment = New-AzPolicyAssignment -Name $PolicyInitiativeName -PolicySetDefinition $InitiativePolicySetDefinition -Scope "/subscriptions/$($subscription)/ResourceGroups/$($ResourceGroupName)"  -IdentityType SystemAssigned -DisplayName $PolicyInitiativeName -Location $Location -WarningAction SilentlyContinue
Write-Host $Assignment.ResourceId
#######################################################
# Grant roles to managed identity at initiative scope #
# https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources?tabs=azure-powershell#grant-permissions-to-the-managed-identity-through-defined-roles
#######################################################
$InitiativeRoleDefinitionIds = @();

#Loop through the policy definitions inside the initiative and gather their role definition IDs
foreach ($policyDefinitionIdInsideInitiative in $InitiativePolicySetDefinition.Properties.PolicyDefinitions.policyDefinitionId) {
    $policyDef = Get-AzPolicyDefinition -Id $policyDefinitionIdInsideInitiative
    $roleDefinitionIds = $policyDef.Properties.PolicyRule.then.details.roleDefinitionIds
    $InitiativeRoleDefinitionIds += $roleDefinitionIds
}

#Create the role assignments used by the initiative assignment at the subscription scope.
if ($InitiativeRoleDefinitionIds.Count -gt 0) {
    $InitiativeRoleDefinitionIds | Sort-Object -Unique | ForEach-Object {
        $roleDefId = $_.Split("/") | Select-Object -Last 1
        try {
            New-AzRoleAssignment -Scope "/subscriptions/$($subscription)" -ObjectId $Assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch {
            # If the identity is not ready yet it will return a bad request, we will simply wait and try again. 
            if ($error[0].Exception -match "BadRequest") {
                Start-Sleep -Seconds 30
                New-AzRoleAssignment -Scope "/subscriptions/$($subscription)" -ObjectId $Assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -ErrorAction Stop -WarningAction SilentlyContinue
            }
            # If the role already exists the New-AzRoleAssignment command will return a Conflict Error. Which we can usually ignore/hide from the console, it will still be in the error stream found in $error.
            elseif ($error[0].Exception -notmatch "Conflict" -AND $error[0].Exception -notmatch "BadRequest") {
                Write-Host $error[0].Exception -ForegroundColor Red
            }
        }
    }
}