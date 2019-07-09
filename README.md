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


### Getting master key from function app 

token=$(/usr/bin/az account get-access-token -o tsv --query accessToken)

echo "token content: $token"

azFuncAccessToken=$(curl "https://$(env)$(fawebhookuri).scm.azurewebsites.net/api/functions/admin/masterkey" -H "Authorization : Bearer $token"  | jq -r  '.masterKey' )


echo "setting up master key : $azFuncAccessToken"


az eventgrid event-subscription create --name "mt9fileadaptersubscription" --source-resource-id "/subscriptions/$(Subscription_id)/resourceGroups/$(env)$(shared_resource_group_name)/providers/Microsoft.Storage/storageaccounts/$(env)$(shared_storage_account)" --endpoint  "https://$(env)$(fawebhookuri).azurewebsites.net/runtime/webhooks/EventGrid?functionName=MyFunctionAppName&code=$azFuncAccessToken" --endpoint-type webhook  --included-event-types Microsoft.Storage.BlobCreated  --subject-begins-with '/test'











