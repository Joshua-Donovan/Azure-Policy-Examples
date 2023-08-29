# CountingDashes [discussion]

## Azure Policy Definition Requirements `[intent]`:
*Contoso requires the ability to set a naming standard of resourceGroups based on the number of dashes in the name. Additionally, we need to be able to validate based on a prefix and postfix pattern.*

> **DISCLAIMER:** This is a custom policy definition. This is **not** a policy definition published by Microsoft and therefore carries no warranty or official support expectation. This is to be used as a teaching tool only. Please always write your own custom policies, fully understand them, and only publish to production after extensive testing in your own **unique** environment!

> **NOTE:** This custom policy shows some "fun" string manipulation techniques in Azure Policy. I would recommend using the `match` functionality and the "?" or "#" regex-like placeholders in a production environment and keeping this type of string manipulation to academic persuits. (my personal opinion)  
> `match` documentation: [https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#:~:text=When%20using%20the%20match%20and%20notMatch%20conditions%2C%20provide%20%23%20to%20match%20a%20digit%2C%20%3F%20for%20a%20letter%2C%20.%20to%20match%20any%20character%2C%20and%20any%20other%20character%20to%20match%20that%20actual%20character.)

## Scope:
This policy will involve the resource type `Microsoft.Resources/resourceGroups`.
> Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?pivots=deployment-language-arm-template

## Functions:
This policy definition utilizes the following Azure Policy and Azure Resource Manager Template functions to accomplish this task:
> `take()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#take  

> `field()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#fields
>
> Using `field()` in a `"value"` condition: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#value

> `parameters()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#parameters 

> `substring()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#substring

> `sub()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-numeric#sub

> `length()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#length

> `empty()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#empty

> `first()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#first

> `split()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-string#split

> `last()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#last

> `add()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-numeric#add

## Assignment Parameter Examples
> `"policyEffect"`   
> Can be entered as a `string` in the Policy Assignment.  
>
> Options:
> > "deny" 
> 
> > "audit"
>
> > "disabled"
> 
> `

> `"dashCount"`   
> Can be entered as an `integer`. This is used to calculate the amount of dashes we want to count, so if we want 5 dashes in our resource group name then we would put 5 here.
>
> Examples:
> > 5
> 
> > 3
> 
> > 1
>
> `

> `"prefixList"`   
> Can be entered as an `array` in the Policy Assignment. Lists allowed prefix values, like if you want all your resourceGroups to start with contoso-prod, contoso-dev, or contoso-test. This can of course be anything you choose.
>
> One limitation of how this is implemented in this example is all the prefix lengths must **match** and you have to put that length in the `take()` function as the second input. Because the length I have chosen is 5, my prefix array members must be 5 characters long, no more, no less. This could probably be improved. 
>
> Examples:
> > ["ABCD-", "efgh-", "IJKL-"] 
> 
> > ["PROD-", "test-", "cDev-"]
> 
> `

> `"postfixPattern"`   
> Can be entered as a `match pattern` (`string`) using the "?" special character for characters and "#" special character for numbers in the Policy Assignment. So, if you'd like all of your resource groups to end with a series of numbers you would add those with "#"
>
> Examples:
> > "##" (ends with two numbers)
> 
> > "??##" (ends with two characters then two numbers)
> 
> `

## The Break Down
---
---
Starting from the top!
```json
"mode": "All", 
```
We are using `"All"` because it is recommended to default to `"All"` unless you have a reason to use `"Indexed"`
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#mode  

---  
--- 
Next lets dive into our `"policyRule"` we will start with the `"if": {}` statement before moving on to the `"then": {}` section. 

### **"if": {}**
```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Resources/resourceGroups"
        },
        {
            "anyOf": [
                {
                    "value": "[take(field('name'), 5)]",
                    "notIn": "[parameters('prefixList')]"
                },
                {
                    "not": {
                        "value": "[substring(field('name'), sub(length(field('name')), length(parameters('postfixPattern'))))]",
                        "match": "[parameters('postfixPattern')]"
                    }
                },
                {
                    "not": {
                        "value": "[if(empty(first(split(field('name'), '-'))), 'emptyStart', if(empty(last(split(field('name'), '-'))), 'emptyEnding', if(equals(length(split(field('name'), '-')),add(parameters('dashCount'), 1)), 'matchesPattern', 'notEnoughorTooManyDashes')))]",
                        "equals": "matchesPattern"
                    }
                }
            ]
        }
    ]
},
```
In our `if: {}` statement our topMost Logical Operator[^1] is `"allOf": []` meaning that all statements in the following array must return true for the Policy to evaluate as **non-compliant** and the `"then": {}` statement to execute. `"allOf": []` is not recursive so only the top level statements need to return true, it does not go deeper than one layer.

For example if we ignore the nested `"anyOf": []` our allOf statement would need the following to trigger the `"then": {}` statement.
```json
"if": {
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Resources/resourceGroups" //needs to return true
        },
        {
            "anyOf": [...] // needs to return true
        }
    ]
},
```

We will go one by one through the statements contained in our `"allOf": []` array.

```json
        {
            "field": "type",
            "equals": "Microsoft.Resources/resourceGroups"
        }
```
This statement is setting our scope for what Policy is checking, using the `"field": "type"` statement is a great way to keep Azure Policy from wasting time checking resources that are not in our intended scope. This statement is simple and returns true or false if the Azure Resouce type equals the specified string.

The next section of our if statement is a nested `"anyOf": []` for this statement to return true only one of the contained conditions need to return true. 

```json
"if": {
    "allOf": [
        {
            ...
        },
        {
            "anyOf": [ // only one of the next three statements need to return true for this entire block to return true.
                {
                    "value": "[take(field('name'), 5)]",
                    "notIn": "[parameters('prefixList')]"
                },
                {
                    "not": {
                        "value": "[substring(field('name'), sub(length(field('name')), length(parameters('postfixPattern'))))]",
                        "match": "[parameters('postfixPattern')]"
                    }
                },
                {
                    "not": {
                        "value": "[if(empty(first(split(field('name'), '-'))), 'emptyStart', if(empty(last(split(field('name'), '-'))), 'emptyEnding', if(equals(length(split(field('name'), '-')),add(parameters('dashCount'), 1)), 'matchesPattern', 'notEnoughorTooManyDashes')))]",
                        "equals": "matchesPattern"
                    }
                }
            ]
        }
    ]
},
```
In our normal pattern, we will go through these condition statements one at a time. Starting with the prefix match. This one is pretty simple and simply takes the first 5 characters of the resource's name.
```json
"if": {
    "allOf": [
        {
            ...
        },
        {
            "anyOf": [ // only one of the next three statements need to return true for this entire block to return true.
                {
                    "value": "[take(field('name'), 5)]",
                    "notIn": "[parameters('prefixList')]"
                },
                {
                    ...
                },
                {
                    ...
                }
            ]
        }
    ]
},
```
So if our resourceGroup's name is "cUAT-myapplication-rg01" and our prefixList is taken from one of the parameter examples above `["PROD-", "test-", "cDev-"]` our `"value":` statement would look like:
```json
{
// start of take -->|     | <-- end of take. Result: "Value": "cUAT-"
    "value": "[take('cUAT-myapplication-rg01', 5)]",
    "notIn": "[parameters('prefixList')]"
},
```
Because **cUAT-** is `notIn` the parameters list `["PROD-", "test-", "cDev-"]` this statement will return `true`, meaning the full `"anyOf": []` will return `true` for this section. 

Otherwise, if our resourceGroup's name is "test-myapplication-rg01" and we keep the same **prefixList**. Then our `notIn` would return `false` meaning the `"anyOf": []` would move on to the next condition statement in its search for truth. *(I'm here all week folks)*

```json
"if": {
    "allOf": [
        {
            ...
        },
        {
            "anyOf": [ // only one of the next three statements need to return true for this entire block to return true.
                {
                    ...
                },
                {
                    "not": {
                        "value": "[substring(field('name'), sub(length(field('name')), length(parameters('postfixPattern'))))]",
                        "match": "[parameters('postfixPattern')]"
                    }
                },
                {
                    ...
                }
            ]
        }
    ]
},
```
Now we will focus on the middle statement in our `"anyOf": []` array. This statement looks for the **postfixPattern** parameter to be contained in the name. This `"value":` statement uses `substring()` to select the end of the name string based on how many characters long our **postfixPattern** parameter is.



[^1]: [Azure Policy Logical Operators](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/