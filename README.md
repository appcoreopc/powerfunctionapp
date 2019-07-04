# powerfunctionapp


Powershell to help you add event hub subscription (webhook). It gets the masterkey and then pass it as part of a request for webhook event


Go to the root folder and then import entire module by using the following command :- 

import-module ./powerfunctionapp


####################################################


How do i get multiple module to load (with the module in different directory)

1. setup your main RootModule = 'test.psm1', which in turn, import other modules 

Import-Module ./util/util.psm1

After that, once you have imported, you also export to function 

Export-ModuleMember -Function Sayhello, SayHello2, SayHello3, GoodBye, GoodBye2, GoodBye3

####################################################


Getting master key from function app 

token=$(/usr/bin/az account get-access-token -o tsv --query accessToken)

echo "token content: $token"

azFuncAccessToken=$(curl "https://$(env)$(fawebhookuri).scm.azurewebsites.net/api/functions/admin/masterkey" -H "Authorization : Bearer $token"  | jq -r  '.masterKey' )

echo "setting up master key : $azFuncAccessToken"

az eventgrid event-subscription create --name "mt9fileadaptersubscription" --source-resource-id "/subscriptions/$(Subscription_id)/resourceGroups/$(env)$(shared_resource_group_name)/providers/Microsoft.Storage/storageaccounts/$(env)$(shared_storage_account)" --endpoint  "https://$(env)$(fawebhookuri).azurewebsites.net/runtime/webhooks/EventGrid?functionName=MyFunctionAppName&code=$azFuncAccessToken" --endpoint-type webhook  --included-event-types Microsoft.Storage.BlobCreated  --subject-begins-with '/test'


https://stackoverflow.com/questions/55492614/setup-azure-function-from-powershell

# Create the Function App
$functionAppName = '4sysops-func'
$newFunctionAppParams = @{
    ResourceType      = 'Microsoft.Web/Sites'
    ResourceName      = $functionAppName
    Kind              = 'functionapp'
    Location          = $location
    ResourceGroupName = $resourceGroupName
    Properties        = @{}
    Force             = $true
}
$functionApp = New-AzureRmResource @newFunctionAppParams
$functionApp

$AppServicePlan = "abc-123"
$AppInsightsKey = "your key here"
$ResourceGroup = "MyRgName"
$Location = "westeurope"
$FunctionAppName = "MyFunctionName"
$AzFunctionAppStorageAccountName = "MyFunctionAppStorageAccountName"
$FunctionAppSettings = @{
    ServerFarmId="/subscriptions/<GUID>/resourceGroups/$ResourceGroup/providers/Microsoft.Web/serverfarms/$AppServicePlan";
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







