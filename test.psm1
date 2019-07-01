function Sayhello {
    Write-Host('helllo there!')
}


function Sayhello2 {
    Write-Host('helllo there!')
}

function Sayhello3 {
    Write-Host('helllo there!')
}



Export-ModuleMember -Function Sayhello, SayHello2, SayHello3
