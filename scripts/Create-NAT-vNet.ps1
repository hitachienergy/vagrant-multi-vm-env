# Creates NAT-enabled vSwitch for Hyper-V (for static IP configuration)
#
# See: https://www.petri.com/using-nat-virtual-switch-hyper-v
#      https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network
#
# Based on:
# 1) https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant/1379582#1379582
# 2) https://github.com/hashicorp/vagrant/issues/8384#issuecomment-548988185

Param(
    [Parameter(HelpMessage = "Name of vSwitch to be created")]
    [String]
    $SwitchName = "NAT Switch",
    # Gateway
    [Parameter(HelpMessage = "Address to use as the NAT gateway IP")]
    [String]
    $IPAddress = "192.168.20.1",
    [Parameter(HelpMessage = "NAT local subnet size (subnet mask)")]
    [Byte]
    $PrefixLength = 24,
    # NAT network
    [Parameter(HelpMessage = "Address prefix of internal interface that connects NAT to internal network")]
    [String]
    $NATNetworkAddressPrefix = "192.168.20.0/24",
    [Parameter(HelpMessage = "Name of NAT object")]
    [String]
    $NATName = "Vagrant on Hyper-V"
)

$ErrorActionPreference = "Stop"

$networkAdapterName = "vEthernet ($SwitchName)"

# Create internal vSwitch
$vSwitchExists = $SwitchName -in (Get-VMSwitch | Select-Object -ExpandProperty Name)
if (-not $vSwitchExists) {
    Write-Host "Creating internal switch `"$SwitchName`" on Windows host..."

    # This command creates also vNIC named "$networkAdapterName"
    New-VMSwitch -SwitchName $SwitchName -SwitchType Internal -Notes "Vagrant on Hyper-V"
}
else {
    $vNICExists = $networkAdapterName -in (Get-NetAdapter | Select-Object -ExpandProperty Name)
    if (-not $vNICExists) {
        throw "Switch `"$SwitchName`" already exists but network adapter `"$networkAdapterName`" not found"
    }
    else {
        Write-Host "Switch `"$SwitchName`" and adapter `"$networkAdapterName`" already exist, skipping"
    }
}

# Configure NAT gateway (assign IP to vNIC)
$currentIPAddress = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq $networkAdapterName } | Select-Object -ExpandProperty IPAddress
if ($currentIPAddress -ne $IPAddress) {
    Write-Host "Registering new IP address `"$IPAddress`" for vSwitch `"$SwitchName`" on Windows host..."

    New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -InterfaceAlias $networkAdapterName
}
else {
    Write-Host "IP address `"$IPAddress`" already registered, skipping"
}

# Configure NAT network
$natNetworkExists = $NATNetworkAddressPrefix -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix)
if (-not $natNetworkExists) {
    Write-Host "Registering new NAT object `"$NATName`" for network `"$NATNetworkAddressPrefix`" on Windows host..."

    New-NetNAT -Name $NATName -InternalIPInterfaceAddressPrefix $NATNetworkAddressPrefix
}
else {
    Write-Host "NAT object for network `"$NATNetworkAddressPrefix`" already registered, skipping"
}
