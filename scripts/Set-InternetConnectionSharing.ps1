#requires -version 5.0
###############################################################################
#  Pseudovector
# 
# Forked form https://github.com/mikefrobbins/PowerShell/blob/master/MrToolkit/Public/Set-MrInternetConnectionSharing.ps1 by Mike F Robbins

###############################################################################

# Always make sure all variables are defined and all best practices are 
# followed.
Set-StrictMode -version Latest

###############################################################################
# Public Cmdlets
###############################################################################
function Set-InternetConnectionSharing() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            If ((Get-NetAdapter -Name $_ -ErrorAction SilentlyContinue -OutVariable INetNIC) -and (($INetNIC).Status -ne 'Disabled' -and ($INetNIC).Status -ne 'Not Present')) {
                $True
            }
            else {
                Throw "$_ is either not a valid network adapter of it's currently disabled."
            }
        })]
        [Alias('Internet')]
        [string[]] $InternetInterfaces,

        [Parameter(Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            If ((Get-NetAdapter -Name $_ -ErrorAction SilentlyContinue -OutVariable INetNIC) -and (($INetNIC).Status -ne 'Disabled' -and ($INetNIC).Status -ne 'Not Present')) {
                $True
            }
            else {
                Throw "$_ is either not a valid network adapter of it's currently disabled."
            }
        })]
        [Alias('Local')]
        [string[]] $LocalInterfaces,

        [Parameter(Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet("True", "False")]
        [String] $Enable
    )

    BEGIN {
        if (-not ($Enabled -eq $true)) {
            $Enabled = $false
        }
        if ((Get-NetAdapter | Get-InternetConnectionSharing).SharingEnabled -contains $true -and $Enabled) {
            Write-Warning -Message 'Unable to continue due to Internet connection sharing already being enabled for one or more network adapters.'
            Break
        }

        regsvr32.exe /s hnetcfg.dll
        $netShare = New-Object -ComObject HNetCfg.HNetShare
    }
    
    PROCESS {

        $publicConnection = $netShare.EnumEveryConnection |
        Where-Object {
            $netShare.NetConnectionProps.Invoke($_).Name -eq $InternetInterfaces
        }

        $publicConfig = $netShare.INetSharingConfigurationForINetConnection.Invoke($publicConnection)

        if ($PSBoundParameters.LocalInterfaces) {
            $privateConnection = $netShare.EnumEveryConnection |
            Where-Object {
                $netShare.NetConnectionProps.Invoke($_).Name -eq $LocalInterfaces
            }

            $privateConfig = $netShare.INetSharingConfigurationForINetConnection.Invoke($privateConnection)
        } 
        
        if ($Enabled -eq $true) {
            $publicConfig.EnableSharing(0)
            if ($PSBoundParameters.LocalInterfaces) {
                $privateConfig.EnableSharing(1)
            }
        }
        else {
            $publicConfig.DisableSharing()
            if ($PSBoundParameters.LocalInterfaces) {
                $privateConfig.DisableSharing()
            }
        }

    }
}