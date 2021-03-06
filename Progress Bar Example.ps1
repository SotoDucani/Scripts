$jobList = @()
$test = 20,30,40,50,60

Foreach($i in $test) {$job = Start-Job -ScriptBlock {Start-Sleep -Seconds 10};$joblist = $joblist + $job}

Do {
    $Total = $jobList.count
    $Complete = ($jobList | Where-Object -FilterScript {$_.State -eq 'Completed'}).count
    Write-Progress -Id 1 -Activity "Running User Creation" -Status "User Creation in Progress: $Complete of $Total" -PercentComplete (($Complete/$Total)*100)
}
Until (($jobList | Where-Object -FilterScript {$_.State -eq 'Running'}).Count -eq 0)