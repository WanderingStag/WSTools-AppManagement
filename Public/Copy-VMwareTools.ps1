function Copy-VMwareTools {
<#
.Notes
    AUTHOR: Skyler Hart
    CREATED: 2021-07-21 23:47:48
    LASTEDIT: 2021-07-21 23:49:09
    KEYWORDS:
    REQUIRES:
        -RunAsAdministrator
.Link
    https://wanderingstag.github.io
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidGlobalVars",
        "",
        Justification = "Have tried other methods and they do not work consistently."
    )]
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Host','Name','Computer','CN')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [int32]$MaxThreads = 5,

        [Parameter()]
        $SleepTimer = 200,

        [Parameter()]
        $MaxResultTime = 1200
    )

Begin {
    $config = $Global:WSToolsConfig
    $app = $config.VMwareTools
    $appname = "VMwareTools"
    $ScriptWD = $config.ScriptWD

        $ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS, $Host)
        $RunspacePool.Open()
        $Code = {
            [CmdletBinding()]
            Param (
                [Parameter(
                    Mandatory=$true,
                    Position=0
                )]
                [string]$comp,

                [Parameter(
                    Mandatory=$true,
                    Position=1
                )]
                [string]$app,

                [Parameter(
                    Mandatory=$true,
                    Position=2
                )]
                [string]$appname,

                [Parameter(
                    Mandatory=$true,
                    Position=3
                )]
                [string]$ScriptWD
            )
            try {
                robocopy $app "\\$comp\c$\Patches\$appname" /mir /mt:3 /r:3 /w:15 /njh /njs
                $end = Get-Date
                $info = [PSCustomObject]@{
                    ComputerName = $comp
                    Program = $appname
                    Status = "Copied"
                    Time = $end
                }#new object
            }
            catch {
                $end = Get-Date
                $info = [PSCustomObject]@{
                    ComputerName = $comp
                    Program = $appname
                    Status = "Failed"
                    Time = $end
                }#new object
            }
            $info | Select-Object ComputerName,Program,Status,Time | Export-Csv $ScriptWD\CopyStatus.csv -NoTypeInformation -Append
        }#end code block
        $Jobs = @()
    }
    Process {
        if (!(Test-Path $ScriptWD)) {mkdir $ScriptWD}
        if (!(Test-Path $ScriptWD\CopyStatus.csv)) {
            $info = [PSCustomObject]@{
                ComputerName = "NA"
                Program = "NA"
                Status = "NA"
                Time = "NA"
            }#new object
            $info | Select-Object ComputerName,Program,Status,Time | export-csv $ScriptWD\CopyStatus.csv -NoTypeInformation
        }
        Write-Progress -Activity "Preloading threads" -Status "Starting Job $($jobs.count)"
        ForEach ($Object in $ComputerName){
            $PowershellThread = [powershell]::Create().AddScript($Code)
            $PowershellThread.AddArgument($Object.ToString()) | out-null
            $PowershellThread.AddArgument($app.ToString()) | out-null
            $PowershellThread.AddArgument($appname.ToString()) | out-null
            $PowershellThread.AddArgument($ScriptWD.ToString()) | out-null
            $PowershellThread.RunspacePool = $RunspacePool
            $Handle = $PowershellThread.BeginInvoke()
            $Job = "" | Select-Object Handle, Thread, object
            $Job.Handle = $Handle
            $Job.Thread = $PowershellThread
            $Job.Object = $Object.ToString()
            $Jobs += $Job
        }
    }
    End {
        $ResultTimer = Get-Date
        While (@($Jobs | Where-Object {$Null -ne $_.Handle}).count -gt 0)  {
            $Remaining = "$($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).object)"
            If ($Remaining.Length -gt 60){
                $Remaining = $Remaining.Substring(0,60) + "..."
            }
            Write-Progress `
                -Activity "Waiting for Jobs - $($MaxThreads - $($RunspacePool.GetAvailableRunspaces())) of $MaxThreads threads running" `
                -PercentComplete (($Jobs.count - $($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).count)) / $Jobs.Count * 100) `
                -Status "$(@($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False})).count) remaining - $remaining"
            ForEach ($Job in $($Jobs | Where-Object {$_.Handle.IsCompleted -eq $True})){
                $Job.Thread.EndInvoke($Job.Handle)
                $Job.Thread.Dispose()
                $Job.Thread = $Null
                $Job.Handle = $Null
                $ResultTimer = Get-Date
            }
            If (($(Get-Date) - $ResultTimer).totalseconds -gt $MaxResultTime){
                Write-Error "Child script appears to be frozen, try increasing MaxResultTime"
                Exit
            }
            Start-Sleep -Milliseconds $SleepTimer
        }
        $RunspacePool.Close() | Out-Null
        $RunspacePool.Dispose() | Out-Null
    }
}
