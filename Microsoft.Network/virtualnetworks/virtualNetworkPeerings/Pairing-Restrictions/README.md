# deny-source-destination-pairing-based-on-VNET-Name [discussion]

## Azure Policy Definition Requirements `[intent]`:
*Contoso requires restrictions on virtualNetwork Peering using two naming standards contained in the id of the peering. The policy must deny both new-deployments included in a `Microsoft.Network/virtualNetworks` deployment or during the creation or update of a `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`. This Azure Policy Definition must restrict the peering of two networks that do not contain matching strings in their ids. For example if a naming standard includes a representation of the Azure Region each Virtual Network is in, then we can restrict the peering of two networks from different regions using this technique. If we have Virtual Networks in Central US (indicated with the naming scheme "C-US" within the Virtual Network Name and therefore contained in the Id) and also Virtual Networks in South Central US (indicated with the naming scheme "SC-US" within the Virtual Network Name and therefore contained in the Id). The question is what if we do not want C-US Virtual Networks to be able to peer with SC-US Virtual Networks? Well, that is what this policy does.*

> **DISCLAIMER:** This is a custom policy definition. This is **not** a policy definition published by Microsoft and therefore carries no warranty or official support expectation. This is to be used as a teaching tool only. Please always write your own custom policies, fully understand them, and only publish to production after extensive testing in your own **unique** environment!

## Scope:
This policy will involve the parent resource type `Microsoft.Network/virtualNetworks` and will also focus on the child resource `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`.
> Parent Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-arm-template

> Child Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-arm-template

## Functions:
This policy utilizes the following Azure Policy and Azure Resource Manager Template functions to accomplish this task:

> `count()`: 
>
>This function counts the number of elements in an array. In this policy, the "count" function is used to count the number of virtual network peerings.
> 
>https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#count  
>
> Specifically we are using the `Value Count` technique: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value-count  
>
> Arrays in Azure Policy Help: https://learn.microsoft.com/en-us/azure/governance/policy/how-to/author-policies-for-arrays

> `anyOf: [] and allOf: []`: 
>
>The anyOf function specifies that at least one of the conditions within it must be true. In this policy, there are two conditions within the "anyOf" function. The allOf function specifies that at least one of the conditions within it must be true. In this policy, there are two conditions within the "anyOf" function.
>
>https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#logical-operators

> `or()`: 
>
> This function specifies that at least one of the conditions within it must be true. In this policy, the "or" function is used to check that the IDs or remote virtual network IDs match the specified patterns.
>
>https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-logical#or

> `and()`: 
>
> This function specifies that all of the conditions within it must be true. In this policy, the "and" function is used to check that both the ID and the remote virtual network ID match the specified patterns.
>
> https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-logical#and

> `split()`: 
>
> This function splits a string into an array based on a specified delimiter. In this policy, the "split" function is used to split the ID and remote virtual network ID into an array based on the "/" delimiter.
>
> https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#split

> `contains()`: 
>
> This function checks if a string contains a specified substring. In this policy, the "contains" function is used to check if the ID or remote virtual network ID contains the specified substring.
>
> https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#contains

> `field()`: 
> 
> This function specifies the field that is being evaluated. In this policy, the "field" function is used to check the type of the resource.
> 
>https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#fields
>
> Using `field()` in a `"value"` condition: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value

> `current()`: 
>
> This function returns the current value of the specified field. In this policy, the "current" function is used to get the current value of the virtual network peering ID and remote virtual network ID.
>
> https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#the-current-function

> `take()`:
>
> This function returns a specified number of elements from the beginning or end of an array. In this policy, the "take" function is used to get the last 9 elements of the array, which represent the resource group and virtual network names.
>
> https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#take

> `last()`:
>
> This function is useful for extracting the specific segments of a resource ID or other string value that are needed for the policy evaluation. In the context of this policy, the "last()" function is used to extract the last element of an array. More specifically, it is used to extract the last segment of the resource ID of the virtual network peering and the remote virtual network ID.
>
> https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#last

> `parameters()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#parameters 

## The Break Down
---  
---  
Starting from the top!
```json
// Azure Policy
{
    "mode": "All", 
```
This attribute specifies the effect of the policy, which can be set to `"All"` or `"Indexed"`. In this case, `"All"` means that the policy is evaluated against all resources within the scope of the policy assignment. We are using `"All"` because it is recommended to default to `"All"` unless you have a reason to use `"Indexed"`.
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#mode  

---  
--- 
Next lets dive into our `"policyRule"` we will start with the `"if": {}` statement before moving on to the `"then": {}` section. The Policy Rule attribute specifies the rule that is applied to resources within the scope of the policy assignment.

# **"if": {}**

This policy definition checks two conditions using the `if` statement:

**Condition 1: Virtual Network Peerings in Virtual Networks**

This condition applies to virtual networks, and it checks whether there are any virtual network peerings that do not meet certain criteria.

The condition uses the following functions:

- `type`: This function checks the type of the resource. In this case, it checks whether the resource is a virtual network.
- `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`: This function checks whether the virtual network has any peerings.
- `count`: This function counts the number of peerings that meet certain criteria. In this case, it counts the number of peerings that have a specific naming convention and remote virtual network ID.

```json
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks"
        },
        {
            "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
            "exists": true
        },
        {
            "count": {
                "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]",
                "where": {
                    "value": "[or(and(contains(split(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id'),'/')[8],'C-US'), contains(split(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id'),'/')[8], 'C-US')),and(contains(split(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id'),'/')[8],'SC-US'), contains(split(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id'),'/')[8], 'SC-US')))]",
                    "equals": false
                }
            },
            "greater": 0
        }
    ]
},
```
Now lets break down the `"Value":` statement contained in the `"where"` portion of our `"count"`, this is the meat of this policy after-all. 

If we split this `"Value"` statement into multiple lines to make it more human readable we can break it down easier (it has to be in one line to work within the Policy Definition.)

```powershell
[
    or( #This is used to check if the ids contain our desired strings in either C-US or SC-US and nothing else
        and( #we want to make sure both source and desitnation peerings return true from the contains and not only one of them. 
            contains( # used to check if our string is in the id segment
                split( # used to segment the resource Id based on '/'
                    current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id'),
                    '/'
                )
                [8], # Indexes to the 8th position in the split array, This is where the VNET name is.
                # Using this indexing method the list starts at 0 and not 1 which is why this is 8 and not 9
                'C-US' # Our string we are validating exists within our Virtual Network name.
            ), 
            contains( # used to check if our string is in the id segment
                split( # used to segment the resource Id based on '/'
                    current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id'),
                    '/'
                )
                [8], # Indexes to the 8th position in the split array, This is where the VNET name is.
                # Using this indexing method the list starts at 0 and not 1 which is why this is 8 and not 9
                'C-US' # Our string we are validating exists within our Virtual Network name.
            )
        ), # End of the first statement, the next statement checks for a different string. (you can add more)
        and(
            contains(
                split(
                    current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id'),
                    '/'
                )
                [8],
                'SC-US' 
            ),
            contains(
                split(
                    current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id'),
                    '/'
                )
                [8],
                'SC-US'
            )
        )
    )
]
```

**Condition 2: Virtual Network Peerings**

This condition applies to virtual network peerings themselves, and it checks whether a given peering meets certain criteria.

The condition uses the following functions:

- `type`: This function checks the type of the resource. In this case, it checks whether the resource is a virtual network peering.
- `value`: This function checks the value of a specific property. In this case, it checks whether the remote virtual network ID has a specific naming convention.

For more information on these functions, please see the following links on Microsoft Learn:

[Azure Policy Definition - Conditions](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#conditions)

[Azure Policy Definition - Functions](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#functions)

```json
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
        },
        {
            "value": "[or(and(contains(last(take(split(field('id'),'/'), 9)),'C-US'),contains(last(take(split(field('Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'),'/'), 9)), 'C-US')),and(contains(last(take(split(field('id'),'/'), 9)),'SC-US'),contains(last(take(split(field('Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'),'/'), 9)), 'SC-US')))]",
            "equals": false
        }
    ]
}
```

This `"value"` statement largely followes the same pattern as our first condiditon except for one change where we are using a different technique for indexing into the array of items. Using the `"last()"` and `"take()"` functions we can get the desired portion of the resource Id (the Virtual Network Name) without explicitely indexing to that position. Why are we doing this?... to show that it can be done, feel free to use only one of these techniques in your actual policy creations :)

Because the rest of this or statement matches above we will simply zoom in on the new things to review.
```powershell
last( # gets the last index in the array, 
    take( # takes a count of indexes from an array, in this case it takes the first 9.
        split(
            field('Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'),
            '/'
        ), 
        9
    )
)

# Therefore, if our resource ID looks like:  
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}

# Then our array would look like: (result from split())
1. {EMPTY}
2. subscriptions
3. {subscriptionId}
4. resourceGroups
5. {resourceGroupName}
6. providers
7. Microsoft.Network
8. virtualNetworks
9. {virtualNetworkName}
10. virtualNetworkPeerings
11. {virtualNetworkPeeringName}

# So selecting the first 9 would stop at {virtualNetworkName} and then selecting the "last()" would return only {virtualNetworkName} 
```
# **"then": {}**
## Actions

If the policy conditions are not met, the policy will take action based on the value of the `effect` parameter. By default, the effect is set to "deny".

## Parameters

This policy definition includes the following parameter:

- `effect`: This parameter specifies whether the policy should be enforced ("deny"), audited ("audit"), or disabled ("disabled").

For more information on parameters, please see the following link on Microsoft Learn:

[Azure Policy Definition - Parameters](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#parameters)




Luckily the `then: {}` statement for this policy is simple, being designed as a **deny** policy it does not need to include resource changes for remediation[^11] and can simply take your choice of effect. ('deny', 'audit', 'disabled').

---
---

And that is it! If you have any questions or if something is unclear feel free to reach out to me through an issue on this repo.

**I wish you the best in your future Azure Cloud adventures!**

