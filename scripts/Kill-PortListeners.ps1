#requires -version 5.0
###############################################################################
#  Pseudovector
# 
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
    [int] $Port,
    [Parameter(Position=1, Mandatory=$false)]
    [switch] $Force
)

function Kill-PortListeners 
{

<#
.SYNOPSIS
Kill tasks listening to port specified by user parameter

.DESCRIPTION
Kill tasks listening to port specified by user parameter

.PARAMETER Port
The port number that is currently listened by targeting tasks
#>

    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [int] $Port,
        [Parameter(Position=1, Mandatory=$false)]
        [switch] $Force
    )

    if (($port -gt 0) -and ($port -le 65535)) 
    {
        [int[]]$pids = Invoke-Expression "netstat -ano" | findstr /I "listening" | findstr /R /C:":$port " | ForEach-Object {($_ -split "\s+")[5]} 
        Write-Host $pids
        $pids = $pids | Select-Object -Unique
        foreach ($pid in @($pids))
        {
            Write-Verbose "Found processes: $pids"
            if ($Force.IsPresent) 
            {
                $pids | ForEach-Object { Invoke-Expression "taskkill /F /pid $_" }
            } 
            else 
            {
                $pids | ForEach-Object { Invoke-Expression "taskkill /pid $_" }
            }
        }
    } 
    else 
    {
        Write-Error -Message "Port specified is out of range"
    }

}

Kill-PortListeners $Port $Force 

