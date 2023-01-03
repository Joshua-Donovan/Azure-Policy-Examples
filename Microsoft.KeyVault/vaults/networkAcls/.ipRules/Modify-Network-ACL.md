# Azure Policy to add required network CIDR ranges

## Azure Policy Definition Requirements `[Intent]`:
*Contoso requires specified IP Addresses and/or IP Address CIDR[^1] ranges have access to their Azure Keyvault resources through the Azure KeyVault Built-In Firewall.*

## Scope:
This policy will involve the parent resource type `Microsoft.KeyVault/vaults` and a focus on the child resource `Microsoft.KeyVault/vaults/networkAcls.ipRules`.
> Azure Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-arm-template

## Functions:
This policy utilizes the following Azure Policy and Azure Resource Manager Template functions to accomplish this task:

> `count`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#count  
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
We are encompacing our **Conditions** in an `"allOf": []` Logical operator statement. This means we will need all of our **Conditions** to evaluate to true for this policy to be **non-compliant** and therefore to execute the `"then": {}` section.
> Documentation: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#logical-operators  

![Image showing code breakdown](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/f563d6e5c6545f3e66b40cb220a1d940f9966eb8/Images/Microsoft.KeyVault.allOf.png)

We can see in the image above that we need both **Conditions** to return `true` for us to continue. Starting with the first condition, this one is pretty simple, if the Azure Resource Type is `Microsoft.KeyVault/vaults` this condition statement will return `true`.

The second condition statement is a bit more complicated. 

We can see that this condition starts with an Azure Policy `Count` function. This function allows us to iterate through arrays within our `"if": {}` statement. Essentially this functions as a simple for loop within Azure Policy. 

```json
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
```

With count we must first identify what we are going to be iterating (looping) through. This must be an **Array** type or the count function will error. In this case we are using the **Value Count** technique which means we need to provide the source array to the count operation as a parameter. The parameter input is through the `"value":` reference.

Next it is a good practice to name our parameter, this is not required but it follows readable code practices to do so. :smile:
We name it through the `"name": "string"` reference, for example in this policy definition I named mine `"name": "aclCidrRanges"`.

Now that we have set up our count function and provided our value parameter we can move on to the logic of the loop.

This is where the `"where": {}` comes in.

In our `"where": {}` statement we need to provide the `"value":` we are measuring and the comparitor we are using to measure. When using count it is expected that the value we are providing will be utilizing our array we provided when setting up the count function. This is shown in the code snippet above, we are addressing the variable we set up in the `current()` function. Because our array in this policy definition is an Object Array (Array containing objects), we can reference the key of one of the object properties through dot sourcing.

But wait?! what about the `current()` function.. don't worry I didn't forget. 

Because the `count` function is an iterative (looping) function we can use the `current()` function to reference the current index of the loop. 

In PowerShell a count loop would look something like: (*History Lesson* - PowerShell was one of my first programming languages so I think in PowerShell a lot of the time, if this just makes things more confusing please ignore)
```powershell
#PowerShell
$MyArray = @("A", "B", "C") # Create Array (equivalant of setting the "value")

for ($i = 0; $i -lt 3; $i++) { # Set up a basic for loop (what "count" is essentially doing) | -lt in PowerShell means lessthan
    $MyArray[$i] # Reference the index of the array member in the current loop (what current() is doing.)
}
```
Then if we add in the `"where": {}` statement:
```powershell
#PowerShell
$MyArray = @("A", "B", "C") # Create Array (equivalant of setting the "value")
$MyCount = 0
for ($i = 0; $i -lt 3; $i++) { # Set up a basic for loop (what "count" is essentially doing) | -lt in PowerShell means lessthan
    if ($MyArray[$i] -eq "A"){ # Take the value at the current index location and compare it to a set value (what "where": {} is doing)
        $MyCount = $MyCount + 1; #Increase the Count if the "Where": {} evaluates to true.
    } 
}
```


---  
  
  


[^1]: [CIDR Notation Explanation](https://devblogs.microsoft.com/premier-developer/understanding-cidr-notation-when-designing-azure-virtual-networks-and-subnets/)
