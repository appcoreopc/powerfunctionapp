
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

function CreateFunctionApp() { 
    
}

function DeployAppFunction($functionAppName, $resourceGroup, $filePath) {
  
    $PublishingProfile = [xml](Get-AzWebAppPublishingProfile -ResourceGroupName $resourceGroup -Name $functionAppName)
    
    $Username = (Select-Xml -Xml $PublishingProfile -XPath "//publishData/publishProfile[contains(@profileName,'Web Deploy')]/@userName").Node.Value
    $Password = (Select-Xml -Xml $PublishingProfile -XPath "//publishData/publishProfile[contains(@profileName,'Web Deploy')]/@userPWD").Node.Value
    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))
    
    $apiUrl = "https://$functionAppName.scm.azurewebsites.net/api/zipdeploy";

    Invoke-RestMethod -Uri $apiUrl -InFile $filePath -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Post -ContentType "multipart/form-date";
}

function ApplySecurityPolicyToFunction {

    ## disable remote debugging 
    ## disable ftp
}

function SetAppSetting($functionAppName, $resourceGroupName, [hashtable] $functionAppSettings) {
  
    $functionAppSettings.add("AzureWebJobsSecretStorageType", "Files")
    $functionAppSettings.add("AzureWebJobsStorage", "")
    
    $setWebAppParams = @{
        Name = $functionAppName
        ResourceGroupName = $resourceGroupName
        AppSettings = $functionAppSettings
    }

    $webApp = Set-AzWebApp @setWebAppParams
}

function IsEventSubscriptionExist($name, $targetResource) {

    Write-Host('helllo there!')
}

function SecureFunctionApp($resourcegroup, $functionAppName) {

    // Disable remote debugging

}


Export-ModuleMember -Function SecureFunctionApp, GetAccessToken, DeployAppFunction, SetAppSetting, CreateEventSubscriptionEventHook, ApplySecurityPolicyToFunction, IsEventSubscriptionExist, GoodBye2, GoodBye3
