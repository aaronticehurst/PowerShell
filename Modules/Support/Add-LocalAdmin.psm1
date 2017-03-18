Function Add-LocalAdmin {
    <#
     .SYNOPSIS
          Adds local admin.
     .DESCRIPTION
           Add a domain user to the local Administrators group on the local or a remote computer.
     .PARAMETER  ComputerName
          The Computer that you are targeting.
	 .PARAMETER	SamAccountName
	 	  Username of person to add as admin.
	 .PARAMETER	Domain
	 	  Domain of user, default is whatever the excutor is logged in as.		  
     .EXAMPLE
	 	  PS C:\> Add-LocalAdmin -ComputerName TESTCOMPUTER -SamAccountName aticehurst
          Add aticehurst as a local admin of TESTCOMPUTER.
	 .EXAMPLE
	      PS C:\> Add-LocalAdmin -ComputerName TESTCOMPUTER -SamAccountName aticehurst -Domain DOMAINNAME
		  Add the DOMAINNAME user aticehurst as a local admin of TESTCOMPUTER
     .NOTES
          Written by Aaron Ticehurst 11/09/2012. 
#>
	 
    param([CmdletBinding()]
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$ComputerName = "$ENV:computername",
        [parameter(Mandatory=$true)]
        [string]$SamAccountName,
        [parameter()]
        [ValidateSet("ticehurst")]
        [string]$Domain = "$ENV:USERDNSDOMAIN"
    )
    Begin{ 
    }

    Process{ 

        $Test = Test-Connection -computername $ComputerName -quiet -count 1
        If ($Test) {
            if ($computerName -eq "") {
                $computerName = "$env:computername"
            } 
            ([ADSI]"WinNT://$computerName/Administrators,group").Add("WinNT://$domain/$SamAccountName")
            if([ADSI]::Exists("WinNT://$computerName,computer")) { 
	
                $computer = [ADSI]("WinNT://" + $ComputerName + ",computer")
                $Group = $computer.psbase.children.find("Administrators")
                $members= $Group.psbase.invoke("Members") | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
		
                if ($members -match (($SamAccountName) -replace "\w*\\","") ){
		
                    Write-Host "User $domain\$SamAccountName is now local administrator on $computerName." 
                }
                else {
                    Write-Host "User $domain\$SamAccountName is not a local administrator on $computerName."
                }	
            }
		
        }
		
        Else {
            Write-host "Cannot ping $ComputerName"
        }

    }

    end{ 
    }		
															
															
}
Export-ModuleMember Add-LocalAdmin