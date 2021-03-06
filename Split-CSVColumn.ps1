# Written to Import a CSV with a publisher column, split on the first comma in that column, and place the first object from the split into it's own column

# Initial CSV file generated via this command:
# Get-AppLockerFileInformation -Directory 'C:\Windows' -FileType exe -Recurse -Verbose | Export-Csv -Path Windows.csv -NoTypeInformation

$CSV = Import-Csv Windows.csv
$CSV | ForEach-Object {
    $PubCompany = $_.Publisher.split(",")[0]
    Write-Host $PubCompany
    $_ | Add-Member -MemberType NoteProperty -Name Company -Value $PubCompany -Force
}
$CSV | Export-Csv -Path 'ModWindows.csv' -NoTypeInformation