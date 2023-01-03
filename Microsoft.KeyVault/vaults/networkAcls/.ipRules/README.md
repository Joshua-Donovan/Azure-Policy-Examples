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
```json
// Azure Policy
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
// Azure Policy
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

In PowerShell a count loop would look something like:

>*History Lesson* - PowerShell was one of my first programming languages so I think in PowerShell a lot of the time, if this just makes things more confusing please ignore
```powershell
# PowerShell
$MyArray = @("A", "B", "C") # Create Array (equivalant of setting the "value" and naming it)

for ($i = 0; $i -lt 3; $i++) { # Set up a basic for loop (what "count" is essentially doing) | -lt in PowerShell means lessthan
    $MyArray[$i] # Reference the index of the array member in the current loop (what current() is doing.)
}
```
Then if we add in the `"where": {}` statement:
```powershell
# PowerShell
$MyAzureResourceList = @("B", "C") # This array represents the existing resources on Azure (The existing CIDR addresses on the KeyVault ACL List)

$MyArray = @("A", "B", "C") # Create Array (equivalant of setting the "value" and naming it)
$MyCount = 0
for ($i = 0; $i -lt 3; $i++) { # Set up a basic for loop (what "count" is essentially doing) | -lt in PowerShell means lessthan
    if ($MyAzureResourceList -contains $MyArray[$i]){ # Take the value at the current index and see if a source array contains the value (what "where": {} is doing)
        $MyCount = $MyCount + 1; #Increase the Count if the "Where": {} evaluates to true.
    } 
}
```

Finally, to finish our **Condition** we must be able to return a boolean[^2] value to our `"allOf": []` because it can only evaluate true and false values. To do this in Azure Policy we use the closing statement of our count that evaluates the number value returned from our loop. In this example that is the `"less": "[length(parameters('aclCidrRanges'))]"` statement. 

This statement is using the `length()` template function to get the length of our parameters array, which will return the count of objects in the array. This count could be different depending on how many 

For one last time, we'll jump back into powershell to add some variety to this example. Outside of our loop we will add one last if statement and some returns from our example function. 

```powershell
# PowerShell
$MyAzureResourceList = @("B", "C") # This array represents the existing resources on Azure (The existing CIDR addresses on the KeyVault ACL List)

$MyArray = @("A", "B", "C") # Create Array (equivalent of setting the "value" and naming it)
$MyCount = 0
for ($i = 0; $i -lt 3; $i++) { # Set up a basic for loop (what "count" is essentially doing) | -lt in PowerShell means lessthan
    if ($MyAzureResourceList -contains $MyArray[$i]){ # Take the value at the current index and see if a source array contains the value (what "where": {} is doing)
        $MyCount = $MyCount + 1; #Increase the Count if the "Where": {} evaluates to true.
    } 
}
# This next statement is the equivalent of our "less": "[length(parameters('aclCidrRanges'))]"
if ($MyCount -lt 3) { # Check if our count is less than (-lt) the count of the $MyArray array, which in this example is 3.
    return true
} else {
    return false
}
```

In Summary of our `"if": {}` statement, if both the Azure Resource type is `"Microsoft.KeyVault/vaults"` and our count shows as less than our array length then... the `then: {}` statement will execute (The `"Microsoft.KeyVault/vaults"` has evaluated to **non-compliant**). Otherwise, if either **condition** is `false` then the Azure Resource will be seen as **compliant** (or ignored if it is not a `"Microsoft.KeyVault/vaults"` resource) and the `then: {}` statement will be skipped. 

---  
---  

### **"then": {}**
```json
// Azure Policy
"then": {
    "effect": "[parameters('effect')]",
    "details": {
        "conflictEffect": "audit",
        "roleDefinitionIds": [
            "/providers/Microsoft.Authorization/roleDefinitions/f25e0fa2-a7c8-4377-a976-54943a77a395"
        ],
        "operations": [
            {
                "operation": "addOrReplace",
                "field": "Microsoft.KeyVault/vaults/networkAcls.ipRules",
                "value": "[union(field('Microsoft.KeyVault/vaults/networkAcls.ipRules[*]'), parameters('aclCidrRanges'))]"
            }
        ]
    }
}
```
Starting from the relative top, we have our `"effect":` which is set to the `"[parameters('effect')]"` string value. Allowed values are `"Modify"`[^3] and `"Disabled"`[^4]. 

Setting to **Modify** will enable this policy to take action and this policy will actively evaluate the Azure Resources in the Policy Assignment Scope during **new deployments** and **updates**. ***Remediation Tasks***[^5] can be used with a **Modify** effect to clean up existing Azure Resources that are not fequently updated. 

Setting to **Disabled** will disable the policy from taking action and the compliance dashboard will default to **Compliant**.

Next we move on to the meat of our `then: {}` statement with the `"details": {}` statement. This section is where our policy pulls its actionable tasks from when **remediating** or taking action during a **new deployment** or **update** on an in scope Azure Resource. 

In this section we have our `"conflictEffect": "audit"`[^3], which can be read about in the Understanding Effects - Modify documentation linked in the footer. For the sake of this note, it is good practice to use this statement in Modify effect Azure Policy Definitions.

Next we have our `"roleDefinitionIds": []`[^6]. This is how we tell Azure Policy what roles to assign to our Managed Identity. In this policy definition we are using the **Built-In Role**[^7] `Key Vault Contributor`

Okay now to the fun part! the `"operations": []` array of statements. This is where we tell Azure Policy what we want it to do! In this Policy Definition we are only giving it one task and that task is to add our `parameters('aclCidrRanges'))]` array of CIDR addresses to the existing list of CIDR addresses on this access control list. 

### ***Short detour...***
Looking at the documentation for the `Microsoft.KeyVault/vaults` resource we can determine the structure/format we need to use to send our list of CIDR addresses. 
> Azure Template Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-arm-template

In this documentation we can see the `"ipRules": []` array is an array of objects with the following structure:
```json
"ipRules": [
    {
        "value": "string"
    }
]
```
Because we want to be able to use the same array parameter `parameters('aclCidrRanges'))]` to check if we are compliant in our if statement and also update the list we will need to make sure this parameter's structure matches the Array of Objects structure that is definied on the `Microsoft.KeyVault/vaults` resource. 

Therefore our `parameters('aclCidrRanges'))]` on the Policy assignment will need to look something like:
```json
[{"value":"192.168.1.0/24"},{"value":"10.0.1.0/23"}]
```
> NOTE: This example contains Private IP Addresses, private IP addresses will fail to apply to the acl list because they are not supported by `Microsoft.KeyVault/vaults/networkAcls.ipRules`. Please only add public IP addresses to this array of objects. (or it will error on every deployment or update to `Microsoft.KeyVault/vaults`)"

### ***Ok back to our operation.***
```json
{
    "operation": "addOrReplace",
    "field": "Microsoft.KeyVault/vaults/networkAcls.ipRules",
    "value": "[union(field('Microsoft.KeyVault/vaults/networkAcls.ipRules[*]'), parameters('aclCidrRanges'))]"
}
```

In this operation our **goal** is to update the ACL list of our KeyVault resource to include the desired CIDR ranges from our `parameters('aclCidrRanges')`. We **do not** want to delete existing CIDR ranges that are not in our parameter, and we also do not want to add duplicates to our ACL list. 

We are using the `"operation": "addOrReplace"`, because we will need to replace the entire ACL array on the Azure KeyVault resource if it exists, or add a new list to the Azure KeyVault if it does not exist. 

In the `"field": "Microsoft.KeyVault/vaults/networkAcls.ipRules"` we are setting the target that we will be updating. In this instance, we want to replace the entire array on the KeyVault ACL resource so we will not be referencing the array members using `[*]`.

In the `"value":` statement we will build what will be our new ACL list on the Azure KeyVault resource. To do this, while keeping our goals in mind, we will be utilizing the `union()` template function. `union()` takes a series of arguments and then outputs them as an array or object. 

We will first reference the **existing** ACL list that lives on the KeyVault resource through the first argument passed to the `union()` function `field('Microsoft.KeyVault/vaults/networkAcls.ipRules[*]')`. 

Then we will reference the CIDR addresses we want to add to the list in the second argument passed to the `union()` function `parameters('aclCidrRanges')`.

***What does this look like practically though?***  
*Glad you asked!*

> NOTE: This example contains Private IP Addresses, private IP addresses will fail to apply to the acl list because they are not supported by `Microsoft.KeyVault/vaults/networkAcls.ipRules`. Please only add public IP addresses to this array of objects. (or it will error on every deployment or update to `Microsoft.KeyVault/vaults`)"

Lets say our `"Microsoft.KeyVault/vaults/networkAcls.ipRules"` contains some exsisting IP Address CIDR ranges in the 10.x.x.x range.
```json
"ipRules": [
    {
        "value": "10.1.1.0/24"
    },
    {
        "value": "10.2.2.0/24"
    }
]
```
This is great, but we want to enforce that some IP Address CIDR ranges are always added in our Policy Scope. For that we will Assign our Policy Definition and add some 192.168.x.x Ip Address CIDR ranges through our policy. 
```json
// Assignment Parameter
[{"value":"192.168.1.0/24"},{"value":"192.168.2.0/24"}]
```

Ok so if we focus into our `union(())` function it would look like:
```json           
//                |       Values from our existing ipRules       | |              Values from our parameter              |
"value": "[union( {'value':'10.1.1.0/24'},{'value':'10.2.2.0/24'} , {'value':'192.168.1.0/24'},{'value':'192.168.2.0/24'}]"
```
Meaning after our `union()` is complete our `"value":` will look like:
```json
"value": [
    {"value":"10.1.1.0/24"},
    {"value":"10.2.2.0/24"},
    {"value":"192.168.1.0/24"},
    {"value":"192.168.2.0/24"}
]
``` 
And after the replace action is complete our ipRules will be:
```json
"ipRules": [
    {
        "value": "10.1.1.0/24"
    },
    {
        "value": "10.2.2.0/24"
    },
    {
        "value": "192.168.1.0/24"
    },
    {
        "value": "192.168.2.0/24"
    }
]
```
***But what about duplicates?!***  
*Glad you asked!* The `union()` function automatically does duplicate detection and if it finds any matching members it will keep the first one only. So as long as your CIDR ranges match exactly (string to string) duplicates wont be an issue.

---
---

And that is it! If you have any questions or if something is unclear feel free to reach out to me through an issue on this repo.

**I wish you the best in your future Azure Cloud adventures!**

[^1]: [CIDR Notation Explanation](https://devblogs.microsoft.com/premier-developer/understanding-cidr-notation-when-designing-azure-virtual-networks-and-subnets/)  
[^2]: [What is a Boolean?](https://en.wikipedia.org/wiki/Boolean_data_type)  
[^3]: [Understanding Effects - Modify](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects#modify)  
[^4]: [Understanding Effects - Disabled](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects#disabled)  
[^5]: [Remediation Documentation](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources?tabs=azure-portal)  
[^6]: [Azure Policy and Azure RBAC](https://learn.microsoft.com/en-us/azure/governance/policy/overview#azure-policy-and-azure-rbac)  
[^7]: [Azure RBAC Built-In Roles Reference](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)  
