function Install-MECM {
<#
.Notes
    AUTHOR: Skyler Hart
    CREATED: 2021-10-12 11:49:19
    LASTEDIT: 2021-10-12 11:55:08
    KEYWORDS:
    REQUIRES:
        -RunAsAdministrator
.Link
    https://wanderingstag.github.io
#>
    [CmdletBinding()]
    [Alias('Install-SCCM')]
    Param (
        [Parameter()]
        [Alias('Host','Name','Computer','CN')]
        [string[]]$ComputerName = "$env:COMPUTERNAME"
    )

    $config = $Global:WSToolsConfig
    $app = $config.MECM

    $b = 0
    $n = $ComputerName.Count
    foreach ($comp in $ComputerName) {
        if ($n -gt 1) {
            $b++
            $p = ($b / $n)
            $p1 = $p.ToString("P")
            Write-Progress -Id 1 -activity "Copying MECM to computer and then initiating install" -status "Computer $b of $n. Percent complete:  $p1" -PercentComplete (($b / $n)  * 100)
        }

        try {
            if ($host.Name -notmatch "ServerRemoteHost") {
                robocopy $app \\$comp\c$\Patches\MECM ccmsetup.exe /r:3 /w:15 /njh /njs
            }
            $install = Invoke-WMIMethod -Class Win32_Process -ComputerName $comp -Name Create -ArgumentList "cmd /c c:\Patches\MECM\ccmsetup.exe" -ErrorAction Stop #DevSkim: ignore DS104456
            $install | Out-Null
            $end = Get-Date
            $info = [PSCustomObject]@{
                ComputerName = $comp
                Status = "Install Initialized"
                Time = $end
            }#new object
        }
        catch {
            $end = Get-Date
            $info = [PSCustomObject]@{
                ComputerName = $comp
                Status = "Unable to install"
                Time = $end
            }#new object
        }
        $info
    }
    Write-Output "The MECM install can take over an install to fully complete. Please wait a minimum of 30 minutes before rebooting or installing another program."
}
