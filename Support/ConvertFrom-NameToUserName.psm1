Function ConvertFrom-NameToUserName {

    #requires -version 2


    <#
    .SYNOPSIS
        Converts names to usernames.
    .DESCRIPTION
        This will convert a staff's name to their username, useful when tickets are lodged that include only names of people affected by the issue.
	.PARAMETER DisplayName
        Name of person.
	.PARAMETER All
        Do a search for every user that shares the display name.
	.PARAMETER IncludeDisabled
        By default the search will only look for enabled users, use -IncludeDisabled switch to include disabled users.	  
    .EXAMPLE
	 	PS C:\test> "aaron ticehurst" | ConvertFrom-NameToUserName
		aticehurst
	.EXAMPLE
	 	PS C:\test> "aaron ticehurst" | ConvertFrom-NameToUserName -IncludeDisabled
		tpaaront
	.EXAMPLE	  
		PS C:\test> "aaron ticehurst" | ConvertFrom-NameToUserName -IncludeDisabled -All
		tpaaront
		aticehurst  
	.NOTES
          Written by Aaron Ticehurst on 16/7/2011. 
		  		  
#>

    Param (
        [CmdletBinding()]
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$DisplayName,
        [Switch]$All,
        [Switch]$IncludeDisabled
    )
    # Bind to domain		
    Begin {
        $BindDomain = [adsisearcher]"" 
    } # Begin
				
    Process {
        Try{
            #Filter result.
            IF ($IncludeDisabled)	{
                $BindDomain.Filter = "(&(objectClass=User)(Displayname=$displayname))" 
            }
            Else {
                $BindDomain.Filter = "(&(objectClass=User)(Displayname=$displayname)(useraccountcontrol=512))"	
            }
				
            IF ($All){
                $Results = $BindDomain.FindAll()
            }
            Else {
                $Results = $BindDomain.FindOne()
            }		
				
            Foreach ($Result in $Results){
                Write-output $Result.properties.samaccountname
            } 		

        }
        #Catch any terminating errors.	
        Catch{
            Throw 
        }	
    } # Process
					
    End { 
    } #End
										
}
										
New-Alias -name CNU -value ConvertFrom-NameToUserName
Export-ModuleMember ConvertFrom-NameToUserName -Alias CNU										