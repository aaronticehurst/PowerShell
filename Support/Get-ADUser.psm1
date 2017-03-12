Function Get-ADUser {

#requires -version 2

<#
    .SYNOPSIS
        Gets user AD details.
    .DESCRIPTION
        Returns a quick summary of 1 or more users active directory account details. Use ADU as the alias.
	.PARAMETER SamAccountName
        Username of person.
	.EXAMPLE
	 	PS C:\Scripts> Get-ADUser aticehurst
		Gets AD details from user aticehurst.
	.EXAMPLE
	 	PS C:\Scripts> 'aticehurst', 'braulio' | Get-ADUser
		Gets AD details from user aticehurst and braulio.
	.NOTES
          Written by Aaron Ticehurst on 6/8/2011. 
		  		  
#>

	Param (
			[CmdletBinding()]
			[parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
			[alias("Identity", "Username")]
			[string]$SamAccountName = $Env:USERNAME,
			[switch]$All,
			[switch]$GroupMembership
			)
			
	Begin 	{
			
			$objDomain = New-Object System.DirectoryServices.DirectoryEntry
			$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
			$objSearcher.SearchRoot = $objDomain
			
			} # Begin

		
				
	Process {
	
			Try{ #Filter result.
					$objSearcher.Filter = ("(&(objectClass=User)(SamAccountName=$SamAccountName))") 
					$Results = $objSearcher.Findone()
			If($All) 	{
				
				If ( $Results -ne $null ) 	{	
								Write-Output $Results | select -ExpandProperty properties
											}
			
						}	
						
												
			Else {											
					
			If ( $Results -ne $null ) {		
				
			
			#Add results into a hash table.	
			Foreach ($Result in $Results){
			
			
				$hash = @{
						SamAccountName = $($Result.properties.samaccountname)
						Name = $($Result.properties.displayname)
						Title = $($Result.properties.title)
						ProfilePath = $($Result.properties.profilepath)
						HomeDirectory = $($Result.properties.homedirectory)
						Email = $($Result.properties.mail)
						EmployeeID = $($Result.properties.employeeid)
						Manager = $($Result.properties.manager)
                        Office = $($Result.properties.physicaldeliveryofficename)
                        Department = $($Result.properties.department)
						Company = $($Result.properties.company)
						OfficePhone = $($Result.properties.telephonenumber)
						LockedOut = $($LockedUser = [ADSI]"WinNT://$env:USERDNSDOMAIN/$SamAccountName"
 									   $ADS_UF_LOCKOUT = 0x00000010
 									    if(($LockedUser.UserFlags.Value -band $ADS_UF_LOCKOUT) -eq $ADS_UF_LOCKOUT) {$true}
										Else { $False }
										)
						Enabled = $(If ($Result.properties.useraccountcontrol -eq 512) {$True}
									ElseIf($Result.properties.useraccountcontrol -eq 514){$False}
									Else {$Result.properties.useraccountcontrol})
						DistinguishedName = $($Result.properties.distinguishedname)
						AccountCreated = $($Result.properties.whencreated)
						MemberOf = $($Results.properties.memberof)
                        PasswordLastSet = $([datetime]::fromfiletime($results.properties.pwdlastset[0]))
													}

						
						
					}
						#Turn Hash table into a synthetic object.										 
						$Object = New-Object PSObject -Property $hash
						#Write object and force order.
						Write-Output $Object | select SamAccountName, Name, Email, Title, EmployeeID, OfficePhone, Manager, Enabled, LockedOut, `
														ProfilePath, HomeDirectory, MemberOf, AccountCreated, DistinguishedName, Office, Department, Company, PasswordLastSet
														}
				If ($GroupMembership) {foreach ($Group in $Results.properties.memberof.getEnumerator()) {(($Group -split ‘,’)[0] -replace ‘CN=’,"")}}
						
																
										}
						
			 
			} 		
										
									
			#Catch any terminatiny errors.	
			Catch{ Throw }	
			} # Process
					
					
	End { } # End
	
	
	}
	
New-Alias -name adu -value Get-ADUser
Export-ModuleMember Get-ADUser -Alias adu