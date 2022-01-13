#requires -version 5.0
###############################################################################
# Copyright (c) 2021 - Pseudovector
# 
# Do whatever you want with this module, but please do give credit.
###############################################################################

# Always make sure all variables are defined and all best practices are 
# followed.
# Set-StrictMode -version Latest

###############################################################################
# Public Cmdlets
###############################################################################
[CmdletBinding()]
param
(
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string] $InstallPath = "$env:USERPROFILE",
    [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string] $RegistryProp = "PATH",
    [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [switch] $Force
)

function Install-Rbenv {
    <#
.SYNOPSIS
Install rbenv-win

.DESCRIPTION
Install rbenv-win

.PARAMETER InstallPath
Path to install rbenv-win, default to %USERPROFILE%\.rbenv

.PARAMETER RegistryProp
Registry Property to keep the path of rbenv as environment variable, default PATH

.PARAMETER Force  
Force install
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $InstallPath = "$env:USERPROFILE",
        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $RegistryProp = "PATH",
        [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch] $Force = $false
    )

    # Get current PATH environment variable
    $RegEntry = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $RegPath = "$RegEntry\$RegistryProp"
    $RegValue = (New-Object -ComObject WScript.Shell).RegRead($RegPath)

    # Add RBENV_ROOT environment variable 
    cmd /c "reg add '$RegEntry' /v RBENV_ROOT /d '$InstPath'"

    # Prepare install path
    $InstPath = "$InstallPath\.rbenv"
    if ( -Not (Test-Path -Path $InstPath) ) {
        Write-Host "Targeting installation path not exists, create now"
        New-Item -Path $InstPath -ItemType Directory 
    }

    # If not installed, start installation now 
    if (( -Not (Test-Path -Path "$InstPath\bin\rbenv.bat")) -or $Force) {
        if (get-Command "git" -ErrorAction SilentlyContinue) {
            git clone https://github.com/nak1114/rbenv-win.git $InstPath
        }
        else {
            throw "git not installed"
        }
    }

    # Update PATH environment variable
    $NewRegValue = $RegValue + "%RBENV_ROOT%\bin;%RBENV_ROOT%\shims;"
    cmd /c "reg add '$RegEntry' /v '$RegistryProp' /d '$NewRegValue'"

    # Check new PATH environment variable
    $RegValue = (New-Object -ComObject WScript.Shell).RegRead($RegPath)
    Write-Host "New PATH user local environment variable : $RegValue"

    Write-Host "Please restart your shell"

}

Install-Rbenv $InstallPath $RegistryProp