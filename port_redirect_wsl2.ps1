# Retrieve the IP address of the WSL Linux machine
$remoteIP = bash.exe -c "ip -4 addr show eth0 | grep 'inet '" | Out-String
$found = $remoteIP -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

if ($found) {
    $remoteIP = $matches[0]
}
else {
    Write-Output "The script will close because the IP address of the WSL 2 machine could not be found."
    exit
}

# Port redirections (Windows -> WSL)
$portMappings = @{
    22   = 22    # SSH : Windows 2222 -> WSL 22
    80   = 80    # HTTP : Windows 8080 -> WSL 80
    443  = 443   # HTTPS : Windows 8443 -> WSL 443
    3390 = 3390  # Custom : Windows 3390 -> WSL 3390
}

$ports_source = $portMappings.Keys -join ","

# Listening IP address on the Windows side
$listenAddr = "0.0.0.0"

# Remove old firewall rules and add new ones
iex "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock'"

# Add new firewall rules allowing inbound and outbound traffic
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -LocalPort $ports_source -Action Allow -Protocol TCP"
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Outbound -LocalPort $ports_source -Action Allow -Protocol TCP"


# Configure port redirection with netsh

foreach ($port_source in $portMappings.Keys) {
    $port_target = $portMappings[$port_source]
    iex "netsh interface portproxy delete v4tov4 listenport=$port_source listenaddress=$listenAddr"
    iex "netsh interface portproxy add v4tov4 listenport=$port_source listenaddress=$listenAddr connectport=$port_target connectaddress=$remoteIP"
}

Write-Output "Port redirection configured successfully."
