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

function Set-WSLStaticIP {
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsFileBackup = "$env:SystemRoot\System32\drivers\etc\hosts.bak"

    $windowsIp = "172.144.111.1"
    $wslIp = "172.144.111.101"
    $wslSubnet = ""
    $windowsHostname = "windows.wsl"
    $wslHostname = ""
    $wslDistName = "Ubuntu"

    function Test-IPAddress ([String] $IPAddress) {
        return $IPAddress -match [ipaddress] $IPAddress
    }
    function Get-DateTime() {
        return Get-Date -Format "yyyy-mm-dd hh:mm:ss"
    }

    function Test-BusyFile([string] $filePath) {
        if (Get-Content $filePath  | Select-Object -First 1) {
            Write-Host (Get-DateTime) "[Test-BusyFile][FILEAVAILABLE]" $filePath
            return $false
        }
        else {
            Write-Host (Get-DateTime) "[Test-BusyFile][FILELOCKED] $filePath is locked"
            return $true
        }
    }

    function Get-HostsEntry ([String] $filename, [String] $hostName) {
        if ([string]::IsNullOrEmpty($hostName) -or $hostName -ne "localhost") {
            $f = Get-Content $filename
            foreach ($line in $f) {
                $bits = [regex]::Split($line, "\s+") | Where-Object { $_ }
                if (( -not $line.startsWith("#")) -and ( $null -ne $bits ) -and ($bits.Count -eq 2 -or $bits.Count -eq 3 )) {
                    if ($bits[1] -eq $hostName) {
                        return $bits[0]
                    }
                }
            }
            return $null
        }
        else {
            throw "Invalid IPAddress or Hostname, Hostname can not be 'localhost'"
        }
    }

    function Add-HostsEntry ([String] $fileName, [String] $hostName, [String] $ipAddress, [String] $description = "") {
        if ($hostName -ne "localhost" -and (Test-IPAddress $ipAddress)) {
            do {
                Start-Sleep -Seconds 2
            } while (Test-BusyFile $fileName)

            if ($ipAddress -ne (Get-HostsEntry $fileName $hostName)) {
                Remove-HostsEntry $fileName $hostName
            }

            if ($null -eq (Get-HostsEntry $fileName $hostName)) {
                if ([string]::IsNullOrEmpty($description)) {
                    $ipAddress + "`t`t" + $hostName | Out-File -Encoding ASCII -Append $fileName
                }
                else {
                    $ipAddress + "`t`t" + $hostName + "`t`t # " + $description | Out-File -Encoding ASCII -Append $fileName
                }
            }
        }
        else {
            throw "Invalid IPAddress or Hostname, Hostname can not be 'localhost'"
        }
    }

    function Remove-HostsEntry ([String] $fileName, [String] $hostName) {
        do {
            Start-Sleep -Seconds 2
        } while (Test-BusyFile $fileName)

        $f = Get-Content $fileName
        $newLines = @()

        # Remove lines match hostname
        foreach ($line in $f) {
            $bits = [regex]::Split($line, "\s+") | Where-Object { $_ }
            if (( -not $line.startsWith("#")) -and ( $null -ne $bits ) -and ($bits.Count -eq 2 -or $bits.Count -eq 3 )) {
                if ($bits[1] -ne $hostName) {
                    $newLines += $line
                }
            }
            else {
                $newLines += $line
            }
        }

        # Write file
        Clear-Content $fileName
        foreach ($line in $newLines) {
            $line | Out-File -Encoding ASCII -Append $fileName
        }
    }

    function Add-WslDnsNameserver() {
        wsl -d $wslDistName -u root bash -c "echo -e nameserver $windowsIp > /etc/resolv.conf"
    }

    try {
        $null, $wslHosts = (wsl -l -v) | Where-Object { $null -ne $_ -and $_ -ne "" }
        foreach ($wslHost in $wslHosts) {
            $hostInfo = $wslHost.Split(" ") | Where-Object { $null -ne $_ -and $_ -ne "" } 
            if ($hostInfo[0] -eq '*' -and $hostInfo.Count -ge 2 ) {
                $hostname = $hostInfo[1] 
                $hostname = $hostname -replace '[\W]', ''
                $wslHostname = $hostname.toLower() + ".wsl"
                break
            }
        }

        $wslSubnet = [regex]::Replace($wslIp, "\.[0-9]{0,3}$", ".255")
        if (( -not [string]::IsNullOrEmpty($wslSubnet)) -and ( -not [string]::IsNullOrEmpty($wslIp)) -and ( -not [string]::IsNullOrEmpty($windowsIp)) -and ( -not [string]::IsNullOrEmpty($windowsHostname)) -and ( -not [string]::IsNullOrEmpty($wslHostname))) {
            # Back up hosts file
            Copy-Item -Path $hostsFile -Destination $hostsFileBackup

            # Clean up existing network interface addresses
            (wsl -d $wslDistName -u root ip addr del $wslIp/32 dev eth0:1)
            (cmd /c netsh int ip delete address "vEthernet (WSL)" $windowsIp 255.255.255.0)
            Write-Host "Existing WSL addresses removed"
            $WslAddIpResult = (wsl -d $wslDistName -u root ip addr add $wslIp/24 broadcast $wslSubnet dev eth0 label eth0:1)
            if ([string]::IsNullOrEmpty($WslAddIpResult)) {
                $winAddIpResult = (cmd /c netsh int ip add address "vEthernet (WSL)" $windowsIp 255.255.255.0)
                if ([string]::IsNullOrEmpty($winAddIpResult)) {
                    Add-HostsEntry $hostsFile $windowsHostname $windowsIp
                    Add-HostsEntry $hostsFile $wslHostname $wslIp
                    Add-WslDnsNameserver
                }
            } 
        }

    }
    catch {
        Write-Host $_.Exception.Message 
        Copy-Item -Path $hostsFileBackup -Destination $hostsFile
    }

}

Set-WSLStaticIP 