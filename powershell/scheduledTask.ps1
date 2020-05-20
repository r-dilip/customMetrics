$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {Get-Process | Select-Object Name,WorkingSet, Id | Export-Csv -Path c:\etc\winakslogperf.csv -Force -NoTypeInformation -Append}"'

$trigger =  New-ScheduledTaskTrigger   -RepetitionInterval (New-TimeSpan -Minutes 1)  -RepetitionDuration (New-TimeSpan -Minutes 10) -At   (Get-Date) -Once

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "perfLog" -Description "Testing perf every minute" -Verbose



