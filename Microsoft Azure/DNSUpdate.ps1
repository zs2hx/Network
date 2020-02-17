#Credits:
#   https://svenmeury.ch/dynamic-dns-updates-with-azure-function-app/
#   https://www.itinsights.org/PowerShell-in-Azure-Functions-v2-is-generally-available/#Passing-Parameters-Repuest

Try
{

    if ($req_query_ipaddr)  
    {   
        #query string param: ipaddr
        $newIpAddress = $req_query_ipaddr 
    }

    if ($newIpAddress)  
    {

	# NB NB NB  Do not change response codes as Mikotik parses them and relies on them

        # =============== [ Azure Settings ] =============== 
        $user = "<azure username here>" 
        $password =  ConvertTo-SecureString "<azure password here>" -AsPlainText -Force 
        $resourceGroupName = "<azure group here>"

        # =============== [ Defaults Settings ] =============== 
        $myTimezone = "<Your time zone here>" # use powershell: Get-TimeZone -ListAvailable
        $recordName = "<name of default A record to update>" #default record to update - or pass through query string, make sure you also have a TXT record. This script will save the last update for informational use.
        $zoneName = "<your zone name here>" #default zone name - or pass through query string

        # =============== [ Settings End ] ===============  

        if ($req_query_recordname)  
        {   
            #query string param: recordname
            $recordName = $req_query_recordname
        }

        if ($req_query_zonename)  
        {
            #query string param: zonename
            $zoneName = $req_query_zonename
        }

        $Credentials = New-Object -typeName System.Management.Automation.PSCredential($user, $password)
        Login-AzureRmAccount -Credential $Credentials

        # A Record - Must exist
        $recordSet = Get-AzureRmDnsRecordSet -name $recordName -RecordType A -ZoneName $zoneName -ResourceGroupName $resourceGroupName
        $exitingIpAddress =$recordSet.Records[0].Ipv4Address;

        #Compare IP's and only update if needed....
        if ($newIpAddress -ne $exitingIpAddress ){

            $recordSet.Records[0].Ipv4Address = $newIpAddress
            Set-AzureRmDnsRecordSet -RecordSet $recordSet

            # TXT Record - Must exist
            $recordSet = Get-AzureRmDnsRecordSet -name $recordName -RecordType TXT -ZoneName $zoneName -ResourceGroupName $resourceGroupName
            $updatedAt = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,$myTimezone).ToString('dd-MM-yyyy HH:mm')

            $msg = "OK. Updated. IP's changed. $recordName.$zoneName IP to $newIpAddress at $updatedAt"
            $recordSet.Records[0].Value = $msg
            Set-AzureRmDnsRecordSet -RecordSet $recordSet
        }else{
            $msg = "OK. Not updated. IP's unchanged. $recordName.$zoneName $newIpAddress :: $exitingIpAddress"
        }

        
    } else{
         $msg = "NOK. No IP address specified"
    }
}Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

    $msg = "NOK. Error occured: $ErrorMessage"

    Break
}
Finally{
    Out-File -Encoding Ascii -FilePath $res -inputObject $msg
}