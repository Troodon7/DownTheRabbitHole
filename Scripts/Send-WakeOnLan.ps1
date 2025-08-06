
function Send-WakeOnLan {
    param (
        [Parameter(Mandatory = $true)]
        [string]$MacAddress,
        [string]$BroadcastAddress = "255.255.255.255",
        [int]$Port = 9
    )

    # Clean MAC string
    $mac = $MacAddress -replace '[:-]', ''

    if ($mac.Length -ne 12) {
        throw "Invalid MAC address format: $MacAddress"
    }

    # Convert MAC string to byte array
    $macBytes = @()
    for ($i = 0; $i -lt 12; $i += 2) {
        $macBytes += [Convert]::ToByte($mac.Substring($i, 2), 16)
    }

    # Build magic packet: 6 x FF followed by MAC repeated 16 times
    $packet = @([byte]0xFF) * 6
    for ($i = 0; $i -lt 16; $i++) {
        $packet += $macBytes
    }

    # Send the packet
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Connect($BroadcastAddress, $Port)
    [void]$udp.Send($packet, $packet.Count)
    $udp.Close()

    Write-Host "Magic packet sent to $MacAddress"
}

# Example usage
Send-WakeOnLan -MacAddress "FF:FF:FF:FF:FF:FF"
