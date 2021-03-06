Set-PSReadLineOption -BellStyle None
function prompt {

	$currentLastExitCode = $LASTEXITCODE
	$lastSuccess = $?
  
	# Colors - PowerShell 7
	<#
	$color = @{
	  Reset = "`e[0m"
	  Red = "`e[31;1m"
	  Green = "`e[32;1m"
	  Yellow = "`e[33;1m"
	  Grey = "`e[37;0m"
	  White = "`e[37;1m"
	  Invert = "`e[7m"
	  RedBackground = "`e[41m"
	}
	#>

	# Colors - PowerShell 5.1
	$color = @{
		Reset = "$([char]0x1b)[0m"
		Red = "$([char]0x1b)[31;1m"
		Green = "$([char]0x1b)[32;1m"
		Yellow = "$([char]0x1b)[33;1m"
		Grey = "$([char]0x1b)[37;0m"
		White = "$([char]0x1b)[37;1m"
		Invert = "$([char]0x1b)[7m"
		RedBackground = "$([char]0x1b)[41m"
	  }
  
	# set color of PS based on success of last execution
	if ($lastSuccess -eq $false) {
	  $lastExit = $color.Red
	} else {
	  $lastExit = $color.Green
	}
  
  
	# get the execution time of the last command  - PowerShell 7
	<#
	$lastCmdTime = ""
	$lastCmd = Get-History -Count 1
	if ($null -ne $lastCmd) {
	  $cmdTime = $lastCmd.Duration.TotalMilliseconds
	  $units = "ms"
	  $timeColor = $color.Green
	  if ($cmdTime -gt 250 -and $cmdTime -lt 1000) {
		$timeColor = $color.Yellow
	  } elseif ($cmdTime -ge 1000) {
		$timeColor = $color.Red
		$units = "s"
		$cmdTime = $lastCmd.Duration.TotalSeconds
		if ($cmdTime -ge 60) {
		  $units = "m"
		  $cmdTIme = $lastCmd.Duration.TotalMinutes
		}
	  }
  
	  $lastCmdTime = "$($color.Grey)[$timeColor$($cmdTime.ToString("#.##"))$units$($color.Grey)]$($color.Reset) "
	}
	#>

	# get the execution time of the last command  - PowerShell 5.1
	$lastCmdTime = ""
	$lastCmd = Get-History -Count 1
	if ($null -ne $lastCmd) {
	  $cmdTimeDuration = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
	  $units = "ms"
	  $timeColor = $color.Green
	  $cmdTime = $cmdTimeDuration.TotalMilliseconds
	  if ($cmdTimeDuration.TotalMilliseconds -gt 250 -and $cmdTimeDuration.TotalMilliseconds -lt 1000) {
		$timeColor = $color.Yellow
	  } elseif ($cmdTimeDuration.TotalMilliseconds -ge 1000) {
		$timeColor = $color.Red
		$units = "s"
		$cmdTime = $cmdTimeDuration.TotalSeconds
		if ($cmdTime -ge 60) {
		  $units = "m"
		  $cmdTIme = $cmdTimeDuration.TotalMinutes
		}
	  }
  
	  $lastCmdTime = "$($color.Grey)[$timeColor$($cmdTime.ToString("#.##"))$units$($color.Grey)]$($color.Reset) "
	}
  
	# get git branch information if in a git folder or subfolder
	$gitBranch = ""
	$path = Get-Location
	while ($path -ne "") {
	  if (Test-Path (Join-Path $path .git)) {
		# need to do this so the stderr doesn't show up in $error
		$ErrorActionPreferenceOld = $ErrorActionPreference
		$ErrorActionPreference = 'Ignore'
		$branch = git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
		$ErrorActionPreference = $ErrorActionPreferenceOld
  
		# handle case where branch is local
		if ($lastexitcode -ne 0 -or $null -eq $branch) {
		  $branch = git rev-parse --abbrev-ref HEAD
		}
  
		$branchColor = $color.Green
  
		if ($branch -match "/master" -or $branch -match "/main") {
		  $branchColor = $color.Red
		}
		$gitBranch = " $($color.Grey)[$branchColor$branch$($color.Grey)]$($color.Reset)"
		break
	  }
  
	  $path = Split-Path -Path $path -Parent
	}
  
	# truncate the current location if too long
	$currentDirectory = $executionContext.SessionState.Path.CurrentLocation.Path
	$consoleWidth = [Console]::WindowWidth
	$maxPath = [int]($consoleWidth / 2)
	if ($currentDirectory.Length -gt $maxPath) {
	  $currentDirectory = "`u{2026}" + $currentDirectory.SubString($currentDirectory.Length - $maxPath)
	}
  
	# check if running dev built pwsh
	$devBuild = ''
	if ($PSHOME.Contains("publish")) {
	  $devBuild = " $($color.White)$($color.RedBackground)DevPwsh$($color.Reset)"
	}
  
	"${lastCmdTime}${currentDirectory}${gitBranch}${devBuild}`n${lastExit}PS$($color.Reset)> "
  
	# set window title
	try {
	  $prefix = ''
	  if ($isWindows) {
		$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
		$windowsPrincipal = [Security.Principal.WindowsPrincipal]::new($identity)
		if ($windowsPrincipal.IsInRole("Administrators") -eq 1) {
		  $prefix = "Admin:"
		}
	  }
  
	  $Host.ui.RawUI.WindowTitle = "$prefix$PWD"
	} catch {
	  # do nothing if can't be set
	}
  
	$global:LASTEXITCODE = $currentLastExitCode
  }

function Get-Google {
	Start-Process "C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe" -ArgumentList 'http://google.com'
}

function Start-NotepadPP {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,Position=0)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$FilePath
	)
	
	$NotepadPP = Get-Item -Path "C:\Program Files\Notepad++\notepad++.exe" -ErrorAction "Stop"
	
	$ArgumentList = ""
	
	if ($FilePath) {
		$ArgumentList = $ArgumentList + "$FilePath "
	}
	
	if ($ArgumentList.length -eq 0) {
		Start-Process -FilePath $NotepadPP.FullName
	} else {
		Start-Process -FilePath $NotepadPP.FullName -ArgumentList $ArgumentList
	}
}

Set-Alias -Name npp -Value Start-NotepadPP
Set-Alias -Name yo -Value ping
Set-Alias -Name gg -Value Get-Google
Set-Alias -Name kubectl -Value kubectl.exe

$Date = Get-Date -UFormat "%h_%d_%Y AT %H_%M_%S"
$LogFile = "C:\Users\cn262427\Documents\WindowsPowerShell\Transcripts\$($Date).txt"
Start-Transcript -Path $LogFile
Write-Host ""
