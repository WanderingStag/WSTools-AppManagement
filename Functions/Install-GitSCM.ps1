function Install-GitSCM {
<#
   .Parameter ComputerName
    Specifies the computer or computers
.Notes
    AUTHOR: Skyler Hart
    CREATED: 2022-09-04 21:50:21
    LASTEDIT: 2022-09-04 21:53:03
    KEYWORDS:
    REQUIRES:
        -RunAsAdministrator
.Link
    https://wanderingstag.github.io
#>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [Alias('Host','Name','Computer','CN')]
        [string[]]$ComputerName = "$env:COMPUTERNAME"
    )

    $config = $Global:WSToolsConfig
    $app = $config.Git

    $b = 0
    $n = $ComputerName.Count
    foreach ($comp in $ComputerName) {
        if ($n -gt 1) {
            $b++
            $p = ($b / $n)
            $p1 = $p.ToString("P")
            Write-Progress -Id 1 -activity "Copying Git SCM to computer and then initiating install" -status "Computer $b of $n. Percent complete:  $p1" -PercentComplete (($b / $n)  * 100)
        }

        try {
            if ($host.Name -notmatch "ServerRemoteHost") {
                robocopy $app \\$comp\c$\Patches\GitSCM /mir /mt:2 /r:3 /w:15 /njh /njs
            }
            $install = Invoke-WMIMethod -Class Win32_Process -ComputerName $comp -Name Create -ArgumentList "cmd /c c:\Patches\GitSCM\Git-64-bit.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /TYPE=full" -ErrorAction Stop #DevSkim: ignore DS104456
            $end = Get-Date
            $info = [PSCustomObject]@{
                ComputerName = $comp
                Status = "Install Initialized"
                Time = $end
            }#pscustomobject
        }
        catch {
            $end = Get-Date
            $info = [PSCustomObject]@{
                ComputerName = $comp
                Status = "Unable to install"
                Time = $end
            }#pscustomobject
        }
        $info
    }
}
