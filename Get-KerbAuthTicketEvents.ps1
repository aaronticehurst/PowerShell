#Get EventID=4768 for last 24 hours from all domain controllers with remoting
Import-Module ActiveDirectory
$dcs = Get-ADDomain |Select -ExpandProperty ReplicaDirectoryServers
$query = @'
<QueryList>
   <Query Id="0" Path="Security">
        <Select Path="Security">*[System[(EventID=4768) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
</Query>
</QueryList>
'@

Get-WinEvent -FilterXml $USING:query -ComputerName $dcs