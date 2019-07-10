# powerfunctionapp

This module requires Az Powershell to help with complexity in setting up Azure App Functions especially when it comes to deployment and setting up event subscription (such as webhooks). Powershell to help you add event hub subscription (webhook). It gets the masterkey and then pass it as part of a request for webhook event

This powershell module aim to help ease that process. 

## Setup all your function app resource

$resourceGroupName = "myfunctionapprg" 
$location = "australiaeast"
$functionAppName = "testappfunction" 
$storageAccountName = "myappstorageaccount"

CreateFunctionApp $resourceGroupName, $location, $functionAppName, $storageAccountName

### Secure function app 

SecureFunctionapp - Typically allows us to disable remote logging and ftps. 

Example 
> SecureFunctionapp $resourcegorupName $functionAppName

### Secure CORS 

Example :-

> SetCors $resourcegorupName $functionAppName $allowOrigin 

### Change your app settings 

SetAppSetting allows you to update your app settings. $settings parameter is a hastable. 

> SetAppSetting $functionAppName $resourceGroup, $settings) 


### Configure App Settings 

Here you need to provide function app name, resource group and then settings infp 

SetAppSetting $functionAppName $ResourceGroupnae @{ Testdata = "test4";Testdata2 = "test3"; FUNCTIONS_EXTENSION_VERSION  = '~2'}        


### Get function app info 

GetFunctionAppInfo $functionAppName $resourcegroupname








