# Azure Policy to add required network CIDR ranges [without the `Count` function]
For this discussion we are going to be focusing only on the second **condition** in our `if: {}` statement. Otherwise this policy is identical to the *Modify-Network-ACL.json* one.

For an in depth break down of this policy please see: [README-Modify-Network-ACL.md](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/b4ba2d356636c5f55c6a14cb895ba936d3772e34/Microsoft.KeyVault/vaults/networkAcls/.ipRules/README.md)

## Functions:
The following functions are used in the **condition statement** we are focused on.
> `equals()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-comparison#equals  

> `intersection()`: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-array#intersection  

> `field()`: https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#fields

## The Condition Statement:

The condition in question, and the only difference from the main policy definition, comes from lines 10-13 in our [Modify-Network-ACL_noLoops.json](https://github.com/Joshua-Donovan/Azure-Policy-Examples/blob/b4ba2d356636c5f55c6a14cb895ba936d3772e34/Microsoft.KeyVault/vaults/networkAcls/.ipRules/Modify-Network-ACL_noLoops.json) policy definition.

```json
{
    "value": "[equals(intersection(field('Microsoft.KeyVault/vaults/networkAcls.ipRules'), parameters('aclCidrRanges')), parameters('aclCidrRanges'))]",
    "equals": false
}
```
Overall our statement can be broken down by function used. We will move from outermost statement to innermost. 

### **The `equals()` Function**
`equals()` compares two arguments and returns a boolean[^1] value determined by if the arguments are equal. In this instance we are seeing if the `intersection()` of the existing IP Address rules and the parameters provided, equals the parameters provided. [we will touch on the `intersection()` function next.]

So, essentially our equals statement is:
```json
//                    | result of intersection function | == | aclCidrRanges parameter array |
    "value": "[equals(           intersection()            ,   parameters('aclCidrRanges')     )]"
```

### **The `intersection()` Function**
`intersection()` is the heart of this **condition statement**, intersection is an Azure Template Function used to compare two arrays and return only the matching values. So, in this case if the values in our `parameters('aclCidrRanges')` matches any values already on the  `"Microsoft.KeyVault/vaults/networkAcls.ipRules"` Azure Resource, those matched values will be returned in the output from the `intersection()` function.

For example, if the `"Microsoft.KeyVault/vaults/networkAcls.ipRules"` Azure Resource looks like:
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
and if our `parameters('aclCidrRanges')` policy assignment parameter looks like:
```json
[{"value":"192.168.1.0/24"},{"value":"10.1.1.0/24"}]
```

Then our result from the `intersection()` function would look like:
```json
[{"value":"10.1.1.0/24"}]]
```
This result shows that only one of the designated CIDR[^2] Address ranges was already on the `"Microsoft.KeyVault/vaults/networkAcls.ipRules"` meaning the `"then": {}` statement will need to execute to add in `{"value":"192.168.1.0/24"}`. (**Non-Compliant**)

If both of our example policy assignment parameters were included on the destination resource it would have returned a value like:
```json
[{"value":"192.168.1.0/24"},{"value":"10.1.1.0/24"}]
```
Which would have resulted in a `true` return from the equals statement allowing us to know all policy assignment parameters are already on the destination resource and skip the `"then": {}` statement. (**Compliant**)
> NOTE: This example contains Private IP Addresses, private IP addresses will fail to apply to the acl list because they are not supported by `Microsoft.KeyVault/vaults/networkAcls.ipRules`. Please only add public IP addresses to this array of objects. (or it will error on every deployment or update to `Microsoft.KeyVault/vaults`)"

### **The `field()` Function**
The `field()` function returns the data from the specified Azure Resource. In this case `Microsoft.KeyVault/vaults/networkAcls.ipRules` would return the current ACL list that is already present. 

---
---

And that is it! If you have any questions or if something is unclear feel free to reach out to me through an issue on this repo.

**I wish you the best in your future Azure Cloud adventures!**


[^1]: [What is a Boolean?](https://en.wikipedia.org/wiki/Boolean_data_type)
[^2]: [CIDR Notation Explanation](https://devblogs.microsoft.com/premier-developer/understanding-cidr-notation-when-designing-azure-virtual-networks-and-subnets/)  