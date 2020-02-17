
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

# ========================= [ Settings Begin ] =========================

# VPN Name as configured in Windows 10
$vpnName = 'vpn.gateway.external.ip.com';

# internal IP of the gateway to other subnets
$vpnGW = '10.0.200.1';

# these hosts / ips are basically just for ping checks
$vpnDest1='10.0.10.0/24';
$vpnDest2='10.0.8.0/24';
$HOST_1 = '10.0.10.150';
$HOST_1_Name = 'host.internal.dns.local';
$HOST_2_Name = 'host.internal.mail.local';
$OTHER_SUBNET_GW_IP = '10.0.8.1';

# ========================= [ Settings End ] =========================


function Connect()
	{
	Write-Output "Connecting..."
	$vpn = Get-VpnConnection -Name $vpnName;

	if($vpn.ConnectionStatus -eq "Disconnected"){
		rasdial $vpnName
	}
	
	$conOK = (Test-Connection -ComputerName $HOST_1  -TimeToLive 5 -Count 2 -Quiet)

	
	if ( $disbaled  ) {
	#if ( !$conOK  ) {
	# this is not used - the windows box has a persistent route...
	# route -p ADD 10.0.8.0 MASK 255.255.255.0 10.0.200.1 IF 67
		if( (Get-NetRoute  | Select-Object -ExpandProperty "NextHop" | Get-Unique).Contains($vpnGW) ){
			Write-Output "Removing route..."
			route delete $vpnDest1
			route delete $vpnDest2
		}
		Write-Output "Adding route 1..."
		New-NetRoute -DestinationPrefix $vpnDest1 -InterfaceAlias $vpnName -NextHop $vpnGW 
		Write-Output "Adding route 2..."
		New-NetRoute -DestinationPrefix $vpnDest2 -InterfaceAlias $vpnName -NextHop $vpnGW 
		
		
	}  
		
	# $conOK = (Test-Connection -ComputerName $HOST_1  -TimeToLive 10 -Count 2 -Quiet)

	if($conOK){
			Write-Output "Connected"
	}else{
			Write-Output "Not Connected"	
	}
}

while ( 1) {
	if ( ! ( Test-Connection -ComputerName $HOST_1 -Count 1 ) ){
		Connect;
	}else{
		Get-Date;
		Test-Connection -ComputerName $vpnGW, $HOST_1, $HOST_1_Name, $OTHER_SUBNET_GW_IP, $HOST_2_Name -Count 1 | Format-Table
	}
}