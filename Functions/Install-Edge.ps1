function Install-Edge {
<#
.NOTES
    Author: Skyler Hart
    Created: 2021-05-25 22:50:45
    Last Edit: 2022-09-04 22:08:12
    Other:
    Requires:
        -RunAsAdministrator
.LINK
    https://wanderingstag.github.io
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Host','Name','Computer','CN')]
        [string[]]$ComputerName = "$env:COMPUTERNAME",

        [Parameter]
        [switch]$Vanilla
    )

    $config = $Global:WSToolsConfig
    if ($Vanilla) {
        $app = $config.EdgeVanilla
    }
    else {
        $app = $config.Edge
    }

    $b = 0
    $n = $ComputerName.Count
    foreach ($comp in $ComputerName) {
        if ($n -gt 1) {
            $b++
            $p = ($b / $n)
            $p1 = $p.ToString("P")
            Write-Progress -Id 1 -activity "Copying Edge to computer and then initiating install" -status "Computer $b of $n. Percent complete:  $p1" -PercentComplete (($b / $n)  * 100)
        }

        try {
            if ($Vanilla) {
                if ($host.Name -notmatch "ServerRemoteHost") {
                    robocopy $app \\$comp\c$\Patches\EdgeVanilla /mir /mt:2 /r:3 /w:15 /njh /njs
                }
                $install = Invoke-WMIMethod -Class Win32_Process -ComputerName $comp -Name Create -ArgumentList "cmd /c msiexec.exe /i c:\Patches\EdgeVanilla\MicrosoftEdgeEnterpriseX64.msi /qn /norestart" -ErrorAction Stop #DevSkim: ignore DS104456
            }
            else {
                if ($host.Name -notmatch "ServerRemoteHost") {
                    robocopy $app \\$comp\c$\Patches\Edge /mir /mt:2 /r:3 /w:15 /njh /njs
                }
                $install = Invoke-WMIMethod -Class Win32_Process -ComputerName $comp -Name Create -ArgumentList "cmd /c c:\Patches\Edge\Deploy-application.exe -DeployMode 'NonInteractive'" -ErrorAction Stop #DevSkim: ignore DS104456
            }

            $end = Get-Date
            $info = New-Object -TypeName PSObject -Property @{
                ComputerName = $comp
                Status = "Install Initialized"
                Time = $end
            }#new object
        }
        catch {
            $end = Get-Date
            $info = New-Object -TypeName PSObject -Property @{
                ComputerName = $comp
                Status = "Unable to install"
                Time = $end
            }#new object
        }
        $info
    }
    Write-Host "Please wait at least five minutes before installing another program" -ForegroundColor Yellow
}
