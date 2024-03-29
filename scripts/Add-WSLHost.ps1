#requires -version 5.0
###############################################################################
#  Pseudovector
# 
###############################################################################

# Always make sure all variables are defined and all best practices are 
# followed.
Set-StrictMode -version Latest

###############################################################################
# Public Cmdlets
###############################################################################

$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsFileBackup = "$env:SystemRoot\System32\drivers\etc\hosts.bak"

function Test-IPAddress ([String] $IPAddress) {
    return $IPAddress -match [ipaddress] $IPAddress
}

function Add-HostsEntry ([String] $fileName, [String] $hostName, [String] $ipAddress, [String] $description="") 
{
    if ($hostName -ne "localhost" -and (Test-IPAddress $ipAddress))
    {
        Remove-HostsEntry $fileName $hostName
        if ([string]::IsNullOrEmpty($description)) {
            $ipAddress + "`t`t" + $hostName | Out-File -Encoding ASCII -Append $fileName
        } else {
            $ipAddress + "`t`t" + $hostName + "`t`t # " + $description | Out-File -Encoding ASCII -Append $fileName
        }
    } else {
        throw "Invalid IPAddress or Hostname, Hostname can not be 'localhost'"
    }
}

function Remove-HostsEntry ([String] $fileName, [String] $hostName) 
{
    $f = Get-Content $fileName
    $newLines = @()

    # Remove lines match hostname
    foreach ($line in $f) 
    {
        $bits = [regex]::Split($line, "\s+") | Where-Object { $_ }
        if (( -not $line.startsWith("#")) -and ( $null -ne $bits ) -and ($bits.Count -eq 2 -or $bits.Count -eq 3 )) 
        {
            if ($bits[1] -ne $hostName) {
                $newLines += $line
            }
        } else {
            $newLines += $line
        }
    }

    # Write file
    Clear-Content $fileName
    foreach ($line in $newLines) {
        $line | Out-File -Encoding ASCII -Append $fileName
    }
}

try {
    $wslIp = (wsl hostname -I)
    $wslHostname = $null
    $adaptorIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "vEthernet (WSL)").IPAddress 
    $windowsHostname = "windows.wsl"
    $null, $wslHosts = (wsl -l -v) | Where-Object { $null -ne $_ -and $_ -ne "" }

    foreach($wslHost in $wslHosts) {
        $hostInfo = $wslHost.Split(" ") | Where-Object { $null -ne $_ -and $_ -ne "" } 
        if ($hostInfo[0] -eq '*' -and $hostInfo.Count -ge 2 ) {
            $hostname = $hostInfo[1] 
            $hostname = $hostname -replace '[\W]',''
            $wslHostname = $hostname.toLower() + ".wsl"
            break
        }
    }

    if (( -not [string]::IsNullOrEmpty($wslHostname)) -and ( -not [String]::IsNullOrEmpty($wslIp))) {
        Copy-Item -Path $hostsFile -Destination $hostsFileBackup
        Start-Sleep -Seconds 1
        Add-HostsEntry $hostsFile $wslHostname $wslIp.trim()
    }

    if (( -not [string]::IsNullOrEmpty($windowsHostname)) -and ( -not [string]::IsNullOrEmpty($adaptorIp))) {
        Copy-Item -Path $hostsFile -Destination $hostsFileBackup
        Start-Sleep -Seconds 1
        Add-HostsEntry $hostsFile $windowsHostname $adaptorIp.trim()
    }
}
catch {
    Copy-Item -Path $hostsFileBackup -Destination $hostsFile
    Write-Host $_.Exception.Message
}

