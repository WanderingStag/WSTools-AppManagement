function Install-VMwareTools {
<#
.SYNOPSIS
    Will install VMware tools on one or more computers.
.DESCRIPTION
    Installes VMware Tools from the C:\Patches\VMware directory. Uses config file to determine network path to copy to the local computer first. On remote computers, install file will need to already exist (use Copy-VMwareTools).
.PARAMETER ComputerName
    Specifies the name of one or more computers to install VMware Tools on.
.EXAMPLE
    C:\PS>Install-VMwareTools
    Will install VMware Tools from setup file in C:\Patches\VMwareTools.
.EXAMPLE
    C:\PS>Install-VMwareTools -ComputerName COMP1,COMP2
    Will install VMware Tools from setup file in C:\Patches\VMwareTools on COMP1 and COMP2.
.NOTES
    Author: Skyler Hart
    Created: 2022-12-16 22:04:04
    Last Edit: 2022-12-16 22:04:04
    Keywords:
    Requires:
        -RunAsAdministrator
.LINK
    https://wanderingstag.github.io
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns",
        "",
        Justification = "Expresses exactly what the function does."
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidGlobalVars",
        "",
        Justification = "Have tried other methods and they do not work consistently."
    )]
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory=$false,
            Position=0
        )]
        [Alias('Host','Name','Computer','CN')]
        [string[]]$ComputerName = "$env:COMPUTERNAME"
    )

    $config = $Global:WSToolsConfig
    $vmtsource = $config.VMwareTools

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        if ($ComputerName -eq $env:COMPUTERNAME) {
            if ($host.Name -notmatch "ServerRemoteHost") {
                Copy-Item -Path $vmtsource -Destination "C:\Patches\VMwareTools"
            }
            Start-Process C:\Patches\VMwareTools\vmware-tools.exe -ArgumentList "/S /v ""/qn REBOOT=R ADDLOCAL=ALL""" -Wait; $rn = (Get-Date).ToUniversalTime().ToString("yyyyMMdd HH:mm:ss UTC"); $string = $rn + " - " + $env:COMPUTERNAME + ":"; Write-Output "$string VMware tools install initiated."
        }
        else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {#DevSkim: ignore DS104456
                Start-Process C:\Patches\VMwareTools\vmware-tools.exe -ArgumentList "/S /v ""/qn REBOOT=R ADDLOCAL=ALL""" -Wait; $rn = (Get-Date).ToUniversalTime().ToString("yyyyMMdd HH:mm:ss UTC"); $string = $rn + " - " + $env:COMPUTERNAME + ":"; Write-Output "$string VMware tools install initiated."
            } -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Error "Must be ran as admin."
    }
}
