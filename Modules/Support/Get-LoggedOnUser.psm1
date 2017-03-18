Function Get-LoggedOnUser {


    #requires -version 2

    <#
    .SYNOPSIS
        Gets who is logged into a pc or terminal.
    .DESCRIPTION
        Returns the logged in users on a desktop or terminal.
	.PARAMETER $ComputerName
        Name of computer to check.
	.EXAMPLE
	 	PS C:\Scripts> Get-LoggedOnUser
		Gets who is logged onto the local machine.
	.EXAMPLE
	 	PS C:\scripts> Get-LoggedOnUser -ComputerName Computer1
		Gets who is logged onto the remote computer.
	.EXAMPLE
	 	PS C:\scripts> Get-Adcomputer -filter {name -like "Computer1*" } | select -expand name  | Get-LoggedOnUser
		Pipe in a list of computernames and check who is logged into each.	
	.NOTES
          Written by Aaron Ticehurst on 26/8/2011. 
		  		  
#>


    Param ([CmdletBinding()]
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$ComputerName = $env:computername)

    Begin { } #Begin

    Process {
        #Create and write out the object
        Function Out-object {
		
            $Object = New-Object PSObject -Property $hash
            Write-Output $Object | select ComputerName, User
							
        }

        #Test if the computer is pingable
        $Test = Test-Connection $ComputerName -Count 1 -Quiet
        If ($Test -eq $true ) {
            Write-Verbose "$ComputerName"	
            $LoggedOnUsers = get-wmiobject win32_process -computername  $ComputerName  | where {$_.name -eq "explorer.exe"} | select __Server, @{n = "owner"; e = {$_.getowner().user}}
            If ($LoggedOnUsers) {
                Foreach ($LoggedOnUser in $LoggedOnUsers) {
				
                    $hash = @{
				
                        ComputerName = $LoggedOnUser.__Server
                        User = $LoggedOnUser.owner
				
                    }
                    Out-object
				
			
                }
            }	
									
            Else {
                $hash = @{
		
                    ComputerName = $ComputerName
                    User = ""
		
                }
                Out-object
					
            }
        }	
        Else {
            $hash = @{
		
                ComputerName = $ComputerName
                User = "Could Not Ping"
		
            }
            Out-object
        }		
								
    } #Process

    End { }	#End


}

New-Alias -name GLU -value Get-LoggedOnUser
Export-ModuleMember Get-LoggedOnUser -Alias GLU