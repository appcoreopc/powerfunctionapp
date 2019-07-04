
Import-Module ./util/util.psm1
Import-Module Az

function CreateResourceGroup($resourceGroupname, $location) {
    New-AzResourceGroup $resourceGroupname $location 
}

function NewStorageAccount($storageName, $resourceGroupname, $location) {
  New-AzStorageAccount -ResourceGroupName $resourceGroupname -AccountName storageName -Location $location -SkuName Standard_LRS
}

function CreateEventSubscriptionEventHook($resourcegroup, $functionName, $subscriptionTitle, $functionCodeName, $resourceId) {

    Write-Host('Updating app settings!')
    ForceAppSettingsAzureWebJobsSecretStorageType $resourcegroup $functionName
    $token = GetAccessToken

    Write-Host('Creating subscription!')
    $azFuncAccessToken = Invoke-WebRequest "https://$functionName.scm.azurewebsites.net/api/functions/admin/masterkey" -Headers @{"Authorization"="Bearer $token"}

    Write-Host($azFuncAccessToken.masterKey)    
    
    $subcriptionStatus = New-AzEventGridSubscription -EventSubscriptionName $subscriptionTitle -ResourceId "$resourceId" -endpoint "https://$functionName.azurewebsites.net/runtime/webhooks/EventGrid?functionName=$functionCodeName&code=$azFuncAccessToken" -EndpointType webhook -IncludedEventType Microsoft.Storage.BlobCreated 
}

## Get token - the same as az account token command ##
function GetAccessToken() {
    $currentAzureContext = Get-AzContext
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;
    return $token
}

function CreateServicePlan($servicePlanName, $resourceGroup, $location) {
    $serviceplan = New-AzAppServicePlan -ResourceGroupName $resourceGroup -Name $servicePlanName -Location $location -Tier "Basic" 
    Write-Host($serviceplan)
    return $serviceplan
}

#####################################################################################
# place holder for code, might have to spit out app service plan codes. 
#####################################################################################
function CreateFunctionApp($functionAppName, $servicePlanName, $storageAccountName,  $resourceGroup, $location) { 
    # setup service plan 
    
    $servicePlan = CreateFunctionApp $servicePlanName $ResourceGroup $location
    $AppServicePlan = $servicePlan.name

    NewStorageAccount $storageAccountName $resourceGroup $location

    # setup storage account 

    ## $AppInsightsKey = "your key here"
    $AzFunctionAppStorageAccountName = "MyFunctionAppStorageAccountName"
    $FunctionAppSettings = @{
        ServerFarmId="/subscriptions/<GUID>/resourceGroups/$resourceGroup/providers/Microsoft.Web/serverfarms/$AppServicePlan";
        alwaysOn=$True;
    }

    # Provision the function app service
    New-AzResource -ResourceGroupName $ResourceGroup -Location $Location -ResourceName $FunctionAppName -ResourceType "microsoft.web/sites" -Kind "functionapp" -Properties $FunctionAppSettings -Force | Out-Null

    $AzFunctionAppStorageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -AccountName $AzFunctionAppStorageAccountName | Where-Object { $_.KeyName -eq "Key1" } | Select-Object Value
    $AzFunctionAppStorageAccountConnectionString = "DefaultEndpointsProtocol=https;AccountName=$AzFunctionAppStorageAccountName;AccountKey=$($AzFunctionAppStorageAccountKey.Value)"
    $AzFunctionAppSettings = @{
        APPINSIGHTS_INSTRUMENTATIONKEY = $AppInsightsKey;
        AzureWebJobsDashboard = $AzFunctionAppStorageAccountConnectionString;
        AzureWebJobsStorage = $AzFunctionAppStorageAccountConnectionString;
        FUNCTIONS_EXTENSION_VERSION = "~2";
        FUNCTIONS_WORKER_RUNTIME = "dotnet";
    }

    # Set the correct application settings on the function app
    Set-AzWebApp -Name $FunctionAppName -ResourceGroupName $ResourceGroup -AppSettings $AzFunctionAppSettings | Out-Null
}

## Get publishing profile and deploy application to scm zipdeploy ##
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
    ## Adding key settings to app config 
    $functionAppSettings.add("AzureWebJobsSecretStorageType", "Files")
    $functionAppSettings.add("AzureWebJobsStorage", "") ## DefaultEndpointsProtocol=https;AccountName=sbsabachofilecreate;AccountKey=2Ukz3jwU1PRgsknLMznHGbLuwk73I9PsBzDTAxedjLRML2Bot4FXFfOW5NZwnbkFN3TTuH3+ZccnLaeYF2qDow==;EndpointSuffix=core.windows.net
    
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
