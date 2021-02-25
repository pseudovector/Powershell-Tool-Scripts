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
    [Parameter(Position=0, Mandatory=$true)]
    [string] $FilePath
)

function Test-FileBusy {
        <#
        .SYNOPSIS
        Check if file is being used 
        
        .DESCRIPTION
        Check if file is being used 
        
        .PARAMETER FilePath
        The path of the file to examine
        #>

        param
        (
            [Parameter(Mandatory=$true)]
            [string] $FilePath
        )

        $text = $null

        if ([string]::IsNullOrEmpty($filePath) -or ( -not (Test-Path $filePath))) {
            write-host (Get-DateTime) "[ACTION][FILECHECK] file $filePath does not exist"
            return $true
        }

        function Get-DateTime() {
            return Get-Date -Format "yyyy-mm-dd hh:mm:ss"
        }

        write-host (Get-DateTime) "[ACTION][FILECHECK] Checking if" $filePath "is locked"

        try {
            $file = [System.io.File]::Open($FilePath, 'Open', 'Read', 'None')
            $reader = New-Object System.IO.StreamReader($file)
            $reader.ReadLine()
            $reader.Close()
            $file.Close()
        } catch [Exception] { 
            $text = $_.Exception.Message 
        }

        if ([string]::IsNullOrEmpty($text)) {
            write-host (Get-DateTime) "[ACTION][FILELOCKED] $filePath is locked"
            return $true
        } else {
            write-host (Get-DateTime) "[ACTION][FILEAVAILABLE]" $filePath
            return $false
        }
}

Test-FileBusy -FilePath $FilePath