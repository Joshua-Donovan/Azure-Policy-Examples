# deny-virtualNetworkPeerings-on-id

## Azure Policy Definition Requirements `[intent]`:
*Contoso requires restrictions on virtualNetwork Peering using string filtering on id. The policy must deny both new-deployments included in a `Microsoft.Network/virtualNetworks` deployment or during the creation or update of a `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` resource if the restricted strings match the id.*

> **DISCLAIMER:** This is a custom policy definition. This is **not** a policy definition published by Microsoft and therefore carries no warranty or official support expectation. This is to be used as a teaching tool only. Please always write your own custom policies, fully understand them, and only publish to production after extensive testing in your own **unique** environment!

## Scope:
This policy will involve the parent resource type `Microsoft.Network/virtualNetworks` and will also focus on the child resource `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`.
> Parent Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-arm-template

> Child Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-arm-template

## Functions:
This policy utilizes the following Azure Policy and Azure Resource Manager Template functions to accomplish this task:

> `count`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#count  
>
> Specifically we are using the `Value Count` technique: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value-count  
>
> Arrays in Azure Policy Help: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/author-policies-for-arrays

> `contains()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#contains

> `toLower()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#tolower

> `field()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#fields
>
> Using `field()` in a `"value"` condition: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value

> `current()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#the-current-function

> `parameters()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#parameters 

## The Break Down
To fulfil the requirements of restricting both new deployments of `Microsoft.Network/virtualNetworks` and `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` we will need to reference them in two separate if statements. These could also be split out into two unique Azure Policies if that separation is desired in the *Compliance Portal*[^1]. For this Policy I am deciding to include both in a single policy, though logically we can think of each resource separately. 

![Image showing logical separation in if statements.](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/35f7e61b28f78c3c0ffd8286c5ae9ee2f06e872b/Images/Microsoft.Network-virtualNetworkPeerings.png)

### **Microsoft.Network/virtualNetworks**



[^1]: [What is the Compliance Portal](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data#portal)  