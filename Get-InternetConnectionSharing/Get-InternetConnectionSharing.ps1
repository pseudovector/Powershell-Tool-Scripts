#requires -version 5.0
###############################################################################
#  Pseudovector
# 
# Forked form https://github.com/mikefrobbins/PowerShell/blob/master/MrToolkit/Public/Get-MrInternetConnectionSharing.ps1 by Mike F Robbins
###############################################################################

# Always make sure all variables are defined and all best practices are 
# followed.
Set-StrictMode -version Latest

###############################################################################
# Public Cmdlets
###############################################################################
function Get-InternetConnectionSharing {

    <#
    .SYNOPSIS
        Retrieves the status of Internet connection sharing for the specified network adapter(s).
    
    .DESCRIPTION
        Get-MrInternetConnectionSharing is an advanced function that retrieves the status of Internet connection sharing
        for the specified network adapter(s).
    
    .PARAMETER InterfaceNames
       The name of the network adapter(s) to check the Internet connection sharing status for.

    .EXAMPLE
       Get-MrInternetConnectionSharing -InternetInterfaceName Ethernet, 'Internal Virtual Switch'

    .EXAMPLE
       'Ethernet', 'Internal Virtual Switch' | Get-MrInternetConnectionSharing

    .EXAMPLE
        Get-NetAdapter | Get-MrInternetConnectionSharing

    .INPUTS
        String
 
    .OUTPUTS
        PSCustomObject
    
    .NOTES
        Author:  Mike F Robbins
        Website: http://mikefrobbins.com
        Twitter: @mikefrobbins
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string[]] $InterfaceNames
    )

    BEGIN {
        regsvr32 /s hnetcfg.dll 
        $netshare = New-Object -ComObject HNetCfg.HNetShare
    }

    PROCESS {
        foreach ($InterfaceName in $InterfaceNames) {
            $publicConnection = $netshare.EnumEveryConnection  | 
            Where-Object {
                $netshare.NetConnectionProps.Invoke($_).Name -eq $InterfaceName     
            }

            try {
                $Results = $netshare.INetSharingConfigurationForINetConnection.Invoke($publicConnection)
            }
            catch {
                Write-Warning -Message "An unexpected error has occurred for network adapter: '$InterfaceName'"
                Continue
            }

            [PSCustomObject]@{
                Name = $InterfaceName
                SharingEnabled = $Results.SharingEnabled
                SharingConnectionType = $Results.SharingConnectionType
                InternetFirewallEnabled = $Results.InternetFirewallEnabled
            }
        }
    }
}
