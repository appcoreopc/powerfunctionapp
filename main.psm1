Import-Module ./util/util.psm1
Import-Module Az

## Create resource group

function CreateResourceGroup($resourceGroupname, $location) {

	Get-AzResourceGroup -Name $resourceGroupname -Location $location -ErrorVariable rgNotExist -ErrorAction SilentlyContinue
	
	if ($rgNotExist)
	{
		$newResourceGroup = New-AzResourceGroup $resourceGroupname $location 
		return $newResourceGroup    
	}
	else 
	{
	   Write-Host("Resource group exist.")
	}
}

# Create storage account 
function NewStorageAccount($storageName, $resourceGroupName, $location) {
 
    $storageAccountExist = $null
    
    try 
    {
        $storageAccountExist = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageName
    }
    catch 
    {
        $storageAccountExist = $null     
    }
    
    if ($null -eq $storageAccountExist) 
    {
      $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageName -Location $location -SkuName Standard_LRS
        return $storageAccount
    }
    else 
    {
      Write-Host("Storage account exists")
    }
}


function CreateEventSubscriptionEventHook($resourcegroup, $functionName, $subscriptionTitle, $functionCodeName, $resourceId) {
  
    ## ForceAppSettingsAzureWebJobsSecretStorageType $resourcegroup $functionName
    
    $token = GetAccessToken  
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

    $svplanExist = Get-AzAppServicePlan -resourcegroupname $resourceGroup -name $servicePlanName 

    if ($null -eq $svplanExist)
    { 
        $svplan = New-AzAppServicePlan -ResourceGroupName $resourceGroup -Name $servicePlanName -Location $location -Tier "Basic" 
        return $svplan    
    }
}

#####################################################################################
# place holder for code, might have to spit out app service plan codes. 
#####################################################################################
function CreateFunctionApp($resourceGroupName, $location, $functionAppName, $storageAccountName) { 
  
    $rg = CreateResourceGroup $resourceGroupName $location

    $svcPlan = CreateServicePlan "DefaultServicePlan" $resourceGroupName $location

    $storageacc = NewStorageAccount $storageAccountName $resourceGroupName $location

    $FunctionAppSettings = @{    
        alwaysOn=$True;
    }

    $webresource = Get-AzResource -name $functionAppName -ResourceGroupName $resourceGroupName -ResourceType "microsoft.web/sites"

    if ($null -eq $webresource) {

         # Provision the function app service
        New-AzResource -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -ResourceName $functionAppName -ResourceType "microsoft.web/sites" -Kind "functionapp" -Properties $FunctionAppSettings -Force 
                      
        Write-Host("Appsettings")
        Write-Host($AzFunctionAppSettings)

        ## Set the correct application settings on the function app
        Set-AzWebApp -Name $functionAppName -ResourceGroupName $rg.ResourceGroupName -AppSettings @{
            #APPINSIGHTS_INSTRUMENTATIONKEY = $AppInsightsKey;
            AzureWebJobsDashboard = $storageacc.Context.ConnectionString;
            AzureWebJobsStorage = $storageacc.Context.ConnectionString;
            FUNCTIONS_EXTENSION_VERSION = "~2";
            FUNCTIONS_WORKER_RUNTIME = "dotnet";    
        } 
    }         
    else
    { 
        Write-Host("App function name already exist")        
    }
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

function SecureFunctionApp($resourceGroupName, $functionAppName) {

    ## disable remote debugging 
    ## disable ftp

    $targetResource = Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $functionAppName -ApiVersion "2018-02-01"

    ## disable remote debugging 
    $targetResource.Properties.remoteDebuggingEnabled = "False"
    $targetResource.Properties.ftpsState = "Disabled"

    ## disable cors ##

    $targetResource | Set-AzResource -ApiVersion "2018-02-01" -Force
}

function SetAppSetting($functionAppName, $resourceGroupName, [hashtable] $functionAppSettings) {
    ## Adding key settings to app config 
    $functionAppSettings.add("AzureWebJobsSecretStorageType", "Files")
      
    $setWebAppParams = @{        
        Name = $functionAppName
        ResourceGroupName = $resourceGroupName
        AppSettings = $functionAppSettings
    }

    $webApp = Set-AzWebApp @setWebAppParams
}

Export-ModuleMember -Function SecureFunctionApp, CreateResourceGroup, GetAccessToken, CreateFunctionApp, CreateServicePlan, DeployAppFunction, SetAppSetting, CreateEventSubscriptionEventHook, ApplySecurityPolicy