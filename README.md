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




