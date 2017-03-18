<#
     .SYNOPSIS
          Records staff logging onto a computer.
     .DESCRIPTION
          Records staff logging onto a computer.
  	 .NOTES
          Written by Aaron Ticehurst 17/10/2016. 
		  		  
#>

$Username =$env:username
$Domain = $env:USERDOMAIN
$ComputerName = $env:computername

Try {
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain


$objSearcher.Filter = ("(&(objectClass=User)(SamAccountName=$Username))")
$UserResults = $objSearcher.Findone()

$objSearcher.Filter = ("(&(objectClass=computer)(name=$ComputerName))")
$ComputerResults = $objSearcher.Findone()

}

Catch {

$Fail = @"
Set-iiLogon
Failed to read AD

$error

$(Get-WmiObject Win32_NetworkAdapterConfiguration  | where-object {$_.ipEnabled -match "True"} |Select IPAddress  | out-string)
"@




        $EventLog = @{ 
			            LogName = 'Application'
				        Source = 'Application Error'
				        Message = "$($fail)"
				        EntryType = 'Information'
				        EventID = 1000
				        ComputerName = "$($env:ComputerName)"
				        }
				        Write-EventLog @EventLog
}

If ($UserResults -and $ComputerResults) {
Try {
                $hash = @{
                UserID = & { $UserObjectGUID = $UserResults.Properties.objectguid ; (new-object guid(,$UserObjectGUID[0])).Guid -replace '-' }
                Logon = "$Domain\$Username"
                ServerGUID = & { $ComputerObjectGUID = $ComputerResults.Properties.objectguid ; (new-object guid(,$ComputerObjectGUID[0])).Guid -replace '-' }
                ServerName = $ComputerName
                LogonTime = (get-date).ToString("yyyy-MM-dd HH:mm:ss")
                                }
                $Object = New-Object -TypeName PSObject -Property $hash


                [string]$ConnectionString = "Server=XXXXXXX;Database=XXXXXXX;Integrated Security=True;Connect Timeout=30"
                $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
			    $connection.ConnectionString = $connectionString
                $connection.Open()
			    $command = $connection.CreateCommand()
                $command.CommandText ="INSERT tblUserLogons VALUES ('$($object.UserID)', '$($object.Logon)', '$($object.ServerGUID)', '$($Object.ServerName)', '$($object.LogonTime)' )"
                $command.ExecuteNonQuery() | Out-Null
                $connection.Close()

}
Catch{
$Fail = @"
Set-iiLogon
Failed to write to database

$($hash |out-string)

$error

$(Get-WmiObject Win32_NetworkAdapterConfiguration  | where-object {$_.ipEnabled -match "True"} |Select IPAddress | out-string)
"@

        $EventLog = @{ 
				        LogName = 'Application'
				        Source = 'Application Error'
				        Message = "$($fail)"
				        EntryType = 'Error'
				        EventID = 1000
				        ComputerName = "$($env:ComputerName)"
				        }
				        Write-EventLog @EventLog
}
}