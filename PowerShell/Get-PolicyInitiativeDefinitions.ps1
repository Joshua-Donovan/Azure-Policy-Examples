
Get-PolicyInitiativeDefinitions ($PolicyInitiativeId) {
    $DefinitionSetProperties = Get-AzPolicySetDefinition -id $PolicyInitiativeId | Select-Object -ExpandProperty Properties
    $UniqueDefinitionIds = $DefinitionSetProperties.PolicyDefinitions.PolicyDefinitionId | Select-Object -Unique
    $Results = $UniqueDefinitionIds | Foreach-Object {
        $id = $_
        $ReferenceId = ($DefinitionSetProperties.PolicyDefinitions | Where-Object {$_.PolicyDefinitionId -eq $id}).PolicyDefinitionReferenceId
        $DisplayName = (Get-AzPolicyDefinition -Id $id | Select-Object -ExpandProperty Properties).DisplayName
        return [PSCustomObject]@{"DefinitionId"="$id"; "DisplayName"="$DisplayName"; "ReferenceId"="$ReferenceId"; "InitiativeName"="$($DefinitionSetProperties.DisplayName)"} 
    }
    return $Results
}