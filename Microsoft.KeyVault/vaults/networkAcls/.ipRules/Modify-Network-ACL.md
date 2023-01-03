# Azure Policy to add required network CIDR ranges

## Azure Policy Definition Requirements `[Intent]`:
*Contoso requires specified IP Addresses and/or IP Address CIDR[^1] ranges have access to their Azure Keyvault resources through the Azure KeyVault Built-In Firewall.*

## Scope:
This policy will involve the parent resource type `Microsoft.KeyVault/vaults` and focus on the child resource `Microsoft.KeyVault/vaults/networkAcls.ipRules`.
> Azure Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-arm-template

## Functions:
This policy utilizes the following Azure Policy and Azure Resource Manager Template functions to accomplish this task:

> `count()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#count  
> Specifically we are using the `Value Count` technique: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value-count
> > Arrays in Azure Policy Help: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/author-policies-for-arrays


> `contains()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#conditions
> > Azure Template Function Doc: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#contains

> `current()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#the-current-function

> `length()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#length

> `parameters()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#parameters 

> `union()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#union

> `field()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#fields
> > Using `field()` in a `"value"` condition: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value

## The Break Down
Starting from the top!
```json
{
    "mode": "All", 
```
We are using `"All"` because it is recommended to default to `"All"` unless you have a reason to use `"Indexed"`
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#mode  

---  
  
Next lets dive into our `"policyRule"` we will start with the `"if": {}` statement before moving on to the `"then": {}` section. 
```json
"if": {
            "allOf": [
                {
                    "field": "type",
                    "equals": "Microsoft.KeyVault/vaults"
                },
                {
                    "count": {
                        "value": "[parameters('aclCidrRanges')]",
                        "name": "aclCidrRanges",
                        "where": {
                            "value": "[contains(field('Microsoft.KeyVault/vaults/networkAcls.ipRules[*].value'), current('aclCidrRanges').value)]",
                            "equals": true
                        }
                    },
                    "less": "[length(parameters('aclCidrRanges'))]"
                }
            ]
        },
```
We are encompacing our `Conditions` in an `"allOf": []` Logical operator statement. This means we will need all of our `Conditions` to evaluate to true for this policy to be `non-compliant` and therefore to execute the `"then": {}` section.
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#logical-operators  

![Image showing code breakdown](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/f563d6e5c6545f3e66b40cb220a1d940f9966eb8/Images/Microsoft.KeyVault.allOf.png)



---  
  
  


[^1]: [CIDR](https://devblogs.microsoft.com/premier-developer/understanding-cidr-notation-when-designing-azure-virtual-networks-and-subnets/)
