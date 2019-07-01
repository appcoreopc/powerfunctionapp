function GoodBye {
    Write-Host('GoodBye there!')
}


function GoodBye2 {
    Write-Host('GoodBye 2 there!')
}

function GoodBye3 {
    Write-Host('GoodBye 3 there!')
}


Export-ModuleMember -Function GoodBye, GoodBye2, GoodBye3
