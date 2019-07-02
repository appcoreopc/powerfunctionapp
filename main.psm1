
Import-Module ./util/util.psm1
Import-Module Az

function CreateEventSubscriptionEventHook($token, $functionName, $subscriptionTitle, $functionCodeName) {

    Write-Host('Creating subscription!')
    $azFuncAccessToken = Invoke-WebRequest "https://$functionName.scm.azurewebsites.net/api/functions/admin/masterkey" -Headers "Authorization : Bearer $token"

    Write-Host($azFuncAccessToken)    

    New-AzEventGridSubscription -EventSubscriptionName $subscriptionTitle -ResourceId "/subscriptions/$(Subscription_id)/resourceGroups/$(env)$(shared_resource_group_name)/providers/Microsoft.Storage/storageaccounts/$(env)$(shared_storage_account)" -endpoint "https://functionName.azurewebsites.net/runtime/webhooks/EventGrid?functionName=$functionCodeName&code=$azFuncAccessToken" -EndpointType webhook -IncludedEventType Microsoft.Storage.BlobCreated 
}

function GetAccessToken() {
    $currentAzureContext = Get-AzContext
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
    $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;
    
}

function IsEventSubscriptionExist($name, $targetResource) {

    Write-Host('helllo there!')
}

function Sayhello3 {
    Write-Host('helllo there!')
}


Export-ModuleMember -Function Sayhello, SayHello2, SayHello3, GoodBye, GoodBye2, GoodBye3
