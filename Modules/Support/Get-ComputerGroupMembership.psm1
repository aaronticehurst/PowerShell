Function Get-ComputerGroupMembership {

    #requires -version 2

    <#
     .SYNOPSIS
          Checks what groups a computer is a member of.
     .DESCRIPTION
          Checks what groups a computer is a member of.
	 .PARAMETER  Name
          Computer you are targetting. 
	 .EXAMPLE
	 	  PS C:\scripts> Get-ComputerGroupMembership -Name COMPUTER1
		  Gets COMPUTER1 group membership.
	  .EXAMPLE
	 	  PS C:\scripts> 'COMPUTER1', 'COMPUTER2' | Get-ComputerGroupMembership
		  Checks multiple computers group membership.	  
	 .NOTES
          Written by Aaron Ticehurst on 11/8/2011. 
		  
		  
#>
    param([CmdletBinding()]
        [parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$Name=$env:computername
			
			
    )
    Begin {
        $a = [adsisearcher]"" 
    }# Begin

    Process {


        Try {
            #Get the group membership of the Computer.	
            $a.Filter =  "(&(objectClass=Computer)(name=$Name))"
            $Results = $a.FindOne() 
            #$Results.properties.memberof
            If ($Results -eq $null) {
                Throw "The Computer was not found" 
            }
            Else{
                Foreach ($Result in $Results)	{

                    $GroupsResult = $Result.properties.memberof

                }
            }	

														
														
            #Clean up the result
            Foreach ($GroupResult in $GroupsResult){
													
                $Split = $GroupResult.IndexOf(",")			
                $Trim = $GroupResult.Substring(0,$Split)
                $Memberof =	$Trim.Substring(3)
                #$GroupResult="" 																			
                #Add to hash table and turn into note properties.					
                $hash = @{
                    Name = $Name
                    MemberOf = $Memberof
																		
                }
				
					
				
                $Object = New-Object PSObject -Property $hash
                Write-Output $Object | select Name, MemberOf	
																					
            }
        }
        Catch {  

            $hash = @{
                Name = $Name
                MemberOf = ""
																		
            }
				
				
				
            $Object = New-Object PSObject -Property $hash
            Write-Output $Object | select Name, MemberOf
					

        }									
				
				}# Process	
			
    End {  
    }# End		
}
										
New-Alias -name GCG -value Get-ComputerGroupMembership									
Export-ModuleMember Get-ComputerGroupMembership -Alias GCG