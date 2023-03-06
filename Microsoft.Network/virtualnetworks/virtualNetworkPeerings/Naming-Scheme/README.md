# deny-virtualNetworkPeerings-on-id (naming scheme enforcement) [discussion]

## Azure Policy Definition Requirements `[intent]`:
*Contoso requires restrictions on virtualNetwork Peering using string filtering on id. The policy must deny both new-deployments included in a `Microsoft.Network/virtualNetworks` deployment or during the creation or update of a `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` resource if the restricted strings match the id. This Azure Policy Definition must be able to filter on multiple input strings sent as an assignment parameter.*

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
---  
---  
Starting from the top!
```json
// Azure Policy
{
    "mode": "All", 
```
We are using `"All"` because it is recommended to default to `"All"` unless you have a reason to use `"Indexed"`
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#mode  

---  
--- 

Next lets dive into our `"policyRule"` we will start with the `"if": {}` statement before moving on to the `"then": {}` section. 

### **"if": {}**

To fulfil the requirements of restricting both new deployments of `Microsoft.Network/virtualNetworks` and `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` we will need to reference them in two separate if statements. These could also be split out into **two unique** Azure Policies if that separation is desired in the *Compliance Portal*[^1]. For this Policy I am deciding to include both in a single policy, though logically we can think of each resource separately. 

![Image showing logical separation in if statements.](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/35f7e61b28f78c3c0ffd8286c5ae9ee2f06e872b/Images/Microsoft.Network-virtualNetworkPeerings.png)

```json
        "if": {
            "anyOf": []
        }
```
In our If statement our topMost Logical Operator[^2] is `"anyOf": []` meaning that if either the `Microsoft.Network/virtualNetworks` **OR** the `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` statements return true the Policy will evaluate to **non-compliant** and the `"then": {}` statement will execute.

### **`Microsoft.Network/virtualNetworks`: Checking New Deployments**
```json
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks"
        },
        {
            "count": {
                ...
            },
            "greater": 0
        }
    ]
},
```
When focusing on `Microsoft.Network/virtualNetworks`, we are using a Logical Operator[^2] of `"allOf": []` meaning every statement contained in this code block must evaluate to true for the entire `"allOf": []` to return true. 

The first check in this Logical Operator[^2] array is:
```json
{
    "field": "type",
    "equals": "Microsoft.Network/virtualNetworks"
},
```
This statement is setting our scope for what Policy is checking, using the `"field": "type"` statement is a great way to keep Azure Policy from wasting time checking resources that are not in our intended scope. This statement is simple and returns true or false if the Azure Resouce type equals the specified string.

Next we dive into the fun part and start working with our requirements in the `count` statement:
```json
{
    "count": {
        "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]",
        "where": {
            "anyOf": [
                {
                    "count": {
                        "value": "[parameters('stringPatterns')]",
                        "name": "stringPattern",
                        "where": {
                            "value": "[contains(toLower(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id')), toLower(current('stringPattern')))]",
                            "equals": true
                        }
                    },
                    "greater": 0
                },
                {
                    "count": {
                        "value": "[parameters('stringPatterns')]",
                        "name": "stringPattern",
                        "where": {
                            "value": "[contains(toLower(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].remoteVirtualNetwork.id')), toLower(current('stringPattern')))]",
                            "equals": true
                        }
                    },
                    "greater": 0
                }
            ]
        }
    },
    "greater": 0
}
```
Remembering that we are focusing on the `Microsoft.Network/virtualNetworks` parent resource in this statement we have to address a fundamental fact of virtual networks. Virtual networks in Azure can have **multiple** virtual network peering configured, meaning the `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` resource reference is an Array[^3] type. This resource needs to be referenced using the `[*]` alias to access the array members. 

We are using `count` to iterate over the `.../virtualNetworkPeerings[*]` resource. Now, because our requirements require the ability to pass multiple strings to filter on we will be utilizing a nested `count` to also iterate through our parameter array containing our filter strings. Nested arrays in Azure Policy can quickly become confusing so I will do my best to explain what is going on clearly here. 

```json
{
    "count": {
        "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]",
        "where": {
            "anyOf": [ // if anyOf the following statements are true, increase parent count number by 1
                {
                    "count": {
                        // If true, increase child count number by 1.
                    },  
                    "greater": 0 // if count greater than 0, return true.
                },
                {
                    "count": {
                        // If true, increase child count number by 1.
                    },
                    "greater": 0 // if count greater than 0, return true.
                }
            ]
        }
    },
    "greater": 0 // if parent count number greater than 0, return true.
}
```
Ok we are going to move one layer deeper here and focus on the `"where": {}` statements of each child `count`.

For the first one inside the parent `count`'s `"anyOf": []` array:
```json
{
    "count": {
        "value": "[parameters('stringPatterns')]",
        "name": "stringPattern",
        "where": {
            "value": "[contains(toLower(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id')), toLower(current('stringPattern')))]",
            "equals": true
        }
    },
    "greater": 0
}
```
For this child `count`, we are going to iterate over our parameter array of **stringPatterns** and then validate if the `.../virtualNetworkPeerings[*].id` string contains our **stringPattern**. When using a **Value Count**[^4] technique, it is good practice to name your variable, we do this through the `"name"` reference directly below our `"value": "[parameters('stringPatterns')]"` reference. In this case I am naming my variable `"stringPattern"`.

This child `count` is focused on the `.../virtualNetworkPeerings[*].id` meaning we are checking the source Resource Id of the `virtualNetworkPeering` for our string matches and not the remote id (we will get to that in the next child `count` statement).

This works in a very similar way to how **PowerShell** foreach loops work. For example:
>*History Lesson* - PowerShell was one of my first programming languages so I think in PowerShell a lot of the time, if this just makes things more confusing please ignore
```powershell
#PowerShell
foreach($stringPattern in $stringPatterns) {
    # You would reference each index of the array inside the loop using the $stringPattern variable.
    # this is the equivalant of referencing $StringPatterns[0].. then $StringPatterns[1]... then $StringPatterns[2]... etc
}
```
Okay, so we have our `stringPattern` iteration variable set up, so let us move into the `"where": {}` statement where we will use it. In the `"where": {}` statement we are using ARM Template Functions[^5] to set the `"value"` reference to a **boolean**[^6] value.


```json
"value": "[
    contains(
        toLower(current('Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].id')),
        toLower(current('stringPattern'))
    )
]"
```
The topMost ARM Template Function[^5] we will be using is `contains()`[^7]. When `contains()`[^7] is used on a string data type, it functions similarly to what you would expaect a **match** function to do. It will search the first input's string for exact matches to the second input's string. Unlike the Azure Policy `"Contains":`[^8] Condition, the ARM Template Function[^5] `contains()`[^7] function is **Case-Sensitive**.

Since we have to deal with the **Case-Sensitive** requirement, the next level down in our statemnent is using the `toLower()`[^9], this ARM Template Function[^5] simply sets all characters in the string to lower case, effectively forcing the `contains()`[^7] ARM Template Function[^5] to be **Case-Insensitive**.

Finally to round out the first input of our `contains()`[^7] ARM Template Function[^5], we will be using the `current()`[^10] Azure Policy function to get the current iteration of the `.../virtualNetworkPeerings[*].id` from the parent `count` iteration.

Bringing this first input together in an example, if our `.../virtualNetworkPeerings[*].id` looks like:
```text
/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_source_vnet/virtualNetworkPeerings/my_source_vnet-my_destination_vnet
```
Then our `contains()`[^7] function would look like the following:
```json
"value": "[
    contains(
        '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_source_vnet/virtualNetworkPeerings/my_source_vnet-my_destination_vnet',
        toLower(current('stringPattern'))
    )
]"
```
Moving on to the second part of the `contains()`[^7] ARM Template Function[^5], we are again using the `current()`[^10] function but this time to get the current iteration of the **stringPattern** variable we set up on the child **Value Count**[^4] earlier.

Bringing the second input together in an example, if our **stringPattern** was `WEB` the `contains()`[^7] function would look like:
```json
"value": "[
    contains(
        '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_source_vnet/virtualNetworkPeerings/my_source_vnet-my_destination_vnet',
        'web'
    )
]"
```

In this example, because `web` is not contained in the my_source_vnet id. The statement will return `false`.
Because the condition of our `count`'s ``"where": {}`` statement is set to `"equals": true`, the condition will evaluate to `false` and will not increase the count. If all `"[parameters('stringPatterns')]"` have the same result (they are not found in the id) then the entire first child `count` will return `false` because the count is not greater than 0.

> **NOTE**: For the inverse effect, if you only want to allow peering to strings contained in the `"[parameters('stringPatterns')]"` parameter instead of restricting by that list, then change the `"equals": true` to `"equals": false` when evaluating the ``"where": {}`` statement's `"value"`.

This leaves us here in our evaluation example:
```json
{
    "count": {
        "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]",
        "where": {
            "anyOf": [ // if anyOf the following statements are true, increase parent count number by 1
                {
                    "count": {
                        // false
                    },  
                    "greater": 0 // count is less than or equal to 0, return false
                },
                {
                    "count": {
                         
                    },
                    "greater": 0 
                }
            ]
        }
    },
    "greater": 0 
}
```

Moving on to the second child `count` statement, we will now focus on the `.remoteVirtualNetwork.id` field. 
This second child `count` statement uses the same `contains()`[^7] ARM Template Function[^5] just with a different first input so we will skip ahead to the example. 

The first input in an example, if our `.../virtualNetworkPeerings[*].remoteVirtualNetwork.id` looks like:
```text
/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_destination_vnet/virtualNetworkPeerings/my_destination_vnet-my_source_vnet
```
Then our `contains()`[^7] function would look like the following:
```json
"value": "[
    contains(
        '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_destination_vnet/virtualNetworkPeerings/my_destination_vnet-my_source_vnet',
        toLower(current('stringPattern'))
    )
]"
```
Moving on to the second part of the `contains()`[^7] ARM Template Function[^5], we are again using the `current()`[^10] function but this time to get the current iteration of the **stringPattern** variable we set up on the child **Value Count**[^4] earlier.

Bringing the second input together in an example, if our **stringPattern** was `DB` the `contains()`[^7] function would look like:
```json
"value": "[
    contains(
        '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/my_destination_vnet/virtualNetworkPeerings/my_destination_vnet-my_source_vnet',
        'db'
    )
]"
```
In this example, because `db` is not contained in the my_destination_vnet id. The statement will return `false`.
Because the condition of our `count`'s ``"where": {}`` statement is set to `"equals": true`, the condition will evaluate to `false` and will not increase the count. If all `"[parameters('stringPatterns')]"` have the same result (they are not found in the id) then the entire first child `count` will return `false` because the count is not greater than 0.

> **NOTE**: For the inverse effect, if you only want to allow peering to strings contained in the `"[parameters('stringPatterns')]"` parameter instead of restricting by that list, then change the `"equals": true` to `"equals": false` when evaluating the ``"where": {}`` statement's `"value"`.

This leaves us here in our evaluation example:
```json
{
    "count": {
        "field": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*]",
        "where": {
            "anyOf": [ // if anyOf the following statements are true, increase parent count number by 1
                {
                    "count": {
                        // false
                    },  
                    "greater": 0 // count is less than or equal to 0, return false
                },
                {
                    "count": {
                         // false
                    },
                    "greater": 0 // count is less than or equal to 0, return false
                }
            ]
        }
    },
    "greater": 0 
}
```
With both child `count`s returning false, the `"anyOf": []` will also return false, meaning the parent `count` will not increase its number. If all parent iterations do not increase the parent's number then the entire parent `count` will return `true` because it's number is not greater than 0.

### **`Microsoft.Network/virtualNetworks/virtualNetworkPeerings`: Checking for Updates and child resource deployments**
Next we will dive into the second condition statement in the root `if: {}`
```json
        "if": {
            "anyOf": []
        }
```
This time we will focus our type on `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`. 
```json
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
        },
        {
            "anyOf": [
                {
                    "count": {
                        ...
                    },
                    "greater": 0
                },
                {
                    "count": {
                        ...
                    },
                    "greater": 0
                }
            ]
        }
    ]
},
```
When focusing on `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`, we are using a Logical Operator[^2] of `"allOf": []` meaning every statement contained in this code block must evaluate to true for the entire `"allOf": []` to return true. 

The first check in this Logical Operator[^2] array is:
```json
{
    "field": "type",
    "equals": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
},
```
This statement is setting our scope for what Policy is checking, using the `"field": "type"` statement is a great way to keep Azure Policy from wasting time checking resources that are not in our intended scope. This statement is simple and returns true or false if the Azure Resouce type equals the specified string.

Moving on to our `count` statements we can breathe a bit knowing that the `"Microsoft.Network/virtualNetworks/virtualNetworkPeerings"` child resource can only contain **one** virtualNetworkPeering and therefore we do not need to have nested loops. We still need to check for both the source id and the remote id, so we will use another `"anyOf": []` condition here.

```json
"anyOf": [
    {
        "count": {
            "value": "[parameters('stringPatterns')]",
            "name": "stringPattern",
            "where": {
                "value": "[contains(toLower(field('id')), toLower(current('stringPattern')))]",
                "equals": true
            }
        },
        "greater": 0
    },
    {
        "count": {
            "value": "[parameters('stringPatterns')]",
            "name": "stringPattern",
            "where": {
                "value": "[contains(toLower(field('Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id')), toLower(current('stringPattern')))]",
                "equals": true
            }
        },
        "greater": 0
    }
]
```
Both of these `count` statements follow the exact patterns already explained above in their `"value"` and `"where": {}`, so I will not repeat that discussion here again. If either `count` statement found here returns true, and the `type` statement also returns true, then the Resource will be labeled **non-compliant** and the `then: {}` statement will execute.

> **NOTE**: For the inverse effect, if you only want to allow peering to strings contained in the `"[parameters('stringPatterns')]"` parameter instead of restricting by that list, then change the `"equals": true` to `"equals": false` when evaluating the ``"where": {}`` statement's `"value"`.

---
---

### **"then": {}**

Luckily the `then: {}` statement for this policy is simple, being designed as a **deny** policy it does not need to include resource changes for remediation[^11] and can simply take your choice of effect. ('deny', 'audit', 'disabled').

---
---

And that is it! If you have any questions or if something is unclear feel free to reach out to me through an issue on this repo.

**I wish you the best in your future Azure Cloud adventures!**


[^1]: [What is the Compliance Portal](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data#portal)  
[^2]: [Azure Policy Logical Operators](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#logical-operators)  
[^3]: [Arrays in Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/author-policies-for-arrays)  
[^4]: [Value Count](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value-count)  
[^5]: [Azure Template Functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions)  
[^6]: [What is a Boolean?](https://en.wikipedia.org/wiki/Boolean_data_type)  
[^7]: [Template Function "contains()"](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#contains)  
[^8]: [Azure Policy Condition "Contains"](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#conditions)  
[^9]: [Template Function "toLower()"](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#tolower)  
[^10]: [Policy Function "current()"](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#the-current-function)  
[^11]: [Remediation Documentation](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources?tabs=azure-portal)  
