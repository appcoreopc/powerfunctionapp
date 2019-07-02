
Import-Module ./util/util.psm1
Import-Module Az

function CreateEventSubscriptionEventHook($resourcegroup, $functionName, $subscriptionTitle, $functionCodeName, $resourceId) {

    Write-Host('Updating app settings!')

    ForceAppSettingsAzureWebJobsSecretStorageType $resourcegroup $functionName

    $token = GetAccessToken

    Write-Host('Creating subscription!')
    $azFuncAccessToken = Invoke-WebRequest "https://$functionName.scm.azurewebsites.net/api/functions/admin/masterkey" -Headers @{"Authorization"="Bearer $token"}

    Write-Host($azFuncAccessToken.masterKey)    
    
    $status = New-AzEventGridSubscription -EventSubscriptionName $subscriptionTitle -ResourceId "$resourceId" -endpoint "https://$functionName.azurewebsites.net/runtime/webhooks/EventGrid?functionName=$functionCodeName&code=$azFuncAccessToken" -EndpointType webhook -IncludedEventType Microsoft.Storage.BlobCreated 
}

function GetAccessToken() {

    $currentAzureContext = Get-AzContext
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;
    return $token
}

function ForceAppSettingsAzureWebJobsSecretStorageType($resourcegroup, $functionName)  {
    az functionapp config appsettings set --name "$functionName" --resource-group "$resourcegroup" --setting "AzureWebJobsSecretStorageType=Files"
}

function DeployAppFunction {
    #PowerShell
$username = "<deployment_user>"
$password = "<deployment_password>"
$filePath = "<zip_file_path>"
$apiUrl = "https://<app_name>.scm.azurewebsites.net/api/zipdeploy"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$userAgent = "powershell/1.0"
Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"

}

functionn ApplySecurityPolicyToFunction {

    ## disable remote debugging 
    ## disable ftp
}

function IsEventSubscriptionExist($name, $targetResource) {

    Write-Host('helllo there!')
}

function Sayhello3 {
    Write-Host('helllo there!')
}


Export-ModuleMember -Function GetAccessToken, ForceAppSettingsAzureWebJobsSecretStorageType, CreateEventSubscriptionEventHook, ApplySecurityPolicyToFunction, IsEventSubscriptionExist, GoodBye2, GoodBye3
