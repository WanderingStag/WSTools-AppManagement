function Install-OneDrive {
<#
   .Parameter ComputerName
    Specifies the computer or computers
.Notes
    AUTHOR: Skyler Hart
    CREATED: 2022-09-04 22:24:27
    LASTEDIT: 2022-09-04 22:24:27
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
    $app = $config.OneDrive

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $b = 0
        $n = $ComputerName.Count
        foreach ($comp in $ComputerName) {
            if ($n -gt 1) {
                $b++
                $p = ($b / $n)
                $p1 = $p.ToString("P")
                Write-Progress -Id 1 -activity "Copying OneDrive to computer and then initiating install" -status "Computer $b of $n. Percent complete:  $p1" -PercentComplete (($b / $n)  * 100)
            }

            try {
                if ($host.Name -notmatch "ServerRemoteHost") {
                    robocopy $app \\$comp\c$\Patches\OneDrive /mir /mt:2 /r:3 /w:15 /njh /njs
                }
                $install = Invoke-WMIMethod -Class Win32_Process -ComputerName $comp -Name Create -ArgumentList "cmd /c c:\Patches\OneDrive\OneDriveSetup.exe /silent /allusers" -ErrorAction Stop #DevSkim: ignore DS104456
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
    else {
        if ($ComputerName -eq $env:COMPUTERNAME) {
            robocopy $app \\$comp\c$\Patches\OneDrive /mir /mt:2 /r:3 /w:15 /njh /njs
            Start-Process -FilePath "C:\Patches\OneDrive\OneDriveSetup.exe" -ArgumentList "/Silent"
        }
        else {
            Write-Warning "Must be ran as admin to install on remote computers."
        }
    }
}
