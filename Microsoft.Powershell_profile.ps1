#Auto Module Imports
#Import-Module posh-git

# Shut PSReadline up
Set-PSReadlineOption -BellStyle None

function prompt {

  $currentLastExitCode = $LASTEXITCODE
  $lastSuccess = $?

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

  # set color of PS based on success of last execution
  if ($lastSuccess -eq $false) {
    $lastExit = $color.Red
  } else {
    $lastExit = $color.Green
  }


  # get the execution time of the last command
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

      if ($branch -match "/master") {
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

  "${lastCmdTime}${currentDirectory}${gitBranch}${devBuild}`n${lastExit}PS$($color.Reset)$('>' * ($nestedPromptLevel + 1)) "

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

function Start-RDPSession {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$Computer,

        [Parameter(Mandatory=$false)]
        [switch]$fullscreen
    )
    begin {
    }
    process {
        foreach ($target in $Computer) {
            try {
                if (!$fullscreen) {
                    Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$($target) /admin /w:1280 /h:800 /prompt" -ErrorAction Stop
                } else {
                    Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$($target) /admin /f /prompt" -ErrorAction Stop
                }
            } catch {
                Write-Error -Message "Could not connect to $($target)." -ErrorAction Continue
            }
        }
    }
    end {
    }
}

function Start-NotepadPP {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,Position=0)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]$FilePath
	)
	
	$NotepadPPexe = Get-Item -Path "C:\Program Files\Notepad++\notepad++.exe" -ErrorAction "Stop"
	
	Start-Process -FilePath $NotepadPPexe.FullName -ArgumentList "$($FilePath)"
}

Function ExtractIcon {

    Param ( 
    [Parameter(Mandatory=$true)]
    [string]$folder
    )

    [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')  | Out-Null

    md $folder -ea 0 | Out-Null

    dir $folder *.exe -ea 0 -rec |
      ForEach-Object { 
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
        Write-Progress "Extracting Icon" $baseName
        [System.Drawing.Icon]::ExtractAssociatedIcon($_.FullName).ToBitmap().Save("$folder\$BaseName.ico")
    }

}

#Custom Alias
Set-Alias -Name gg -Value Get-Google
Set-Alias -Name yo -Value ping
Set-Alias -Name npp -Value Start-NotepadPP

#Finally; Start a transcript
$date = get-date -UFormat "%h_%d_%Y AT %H_%M_%S"
$logfile = "J:\PowerShell\Transcripts\$date.txt"
Start-Transcript -Path $logfile