Function Compare-GroupMembership {

    #requires -version 2


    <#
     .SYNOPSIS
          Returns the difference of group membership between two objects.
     .DESCRIPTION
          Takes two objects, A (the reference object) and B (the difference object) and compares their group membership. 
		  The result will return a list of groups that A is a member of but B is not.
	 .PARAMETER  Referenceobject
          The object who we wish to compare to.
	 .PARAMETER  Differenceobject
          The object to determine what it is not a part of that A is a part of.	 		 
     .EXAMPLE
	 	  PS C:\scripts\> Compare-GroupMembership -ReferenceObject Aaron -DifferenceObject Braulio
		  Determines what groups Aaron is a part of that Braulio is not.
	 .NOTES
          Written by Aaron Ticehurst on 9/4/2011. 
		  Update 13/01/2013
		  		  
#>

    param(
        [CmdletBinding()]
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [string]$ReferenceObject,
							
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [string]$DifferenceObject
    )
							
				#Get the group membership of the difference object.			
    $a = [adsisearcher]""
    $a.Filter = "SamAccountName=$DifferenceObject"
    $Results = $a.FindOne() 
    If ($Results -eq $null) {
        Throw "The difference object was not found" 
    }
    Else{
        Foreach ($Result in $Results)	{

            $ArrResult = $Result.properties.memberof

        }
    }							
							
    #Get the group membership of the reference object.
    $b = [adsisearcher]""
    $b.Filter = "SamAccountName=$ReferenceObject"
    $RefResults = $b.FindOne() 
    If ($RefResults -eq $null) {
        Throw "The reference object was not found" 
    }
    Else{
								Foreach ($RefResult in $RefResults){

            $ReferenceResult = $RefResult.properties.memberof
					
        }
    }
    #Compare the Membership of both objects.
    Foreach ($RefGroup in $ReferenceResult) {
											
        $CompareResult = $ArrResult -contains $RefGroup
        If ($CompareResult -eq $false) {
																	
            $c = [adsisearcher]""
												$c.Filter = "DistinguishedName=$RefGroup"
												$GroupResults = $c.FindOne() 
												
												
												
            #Clean up the result	
												$Split = $RefGroup.IndexOf(",")			
												$Trim = $RefGroup.Substring(0,$Split)
												$NotAMemberof =	$Trim.Substring(3)
																					
            #Add to hash table and turn into note properties.					
            $hash = @{
																Object = $DifferenceObject
																NotAMemberOf = $NotAMemberof
																Description = $($GroupResults.properties.description)
        }
																 
        $Object = New-Object PSObject -Property $hash
        Write-Output $Object | select object, NotAMemberOf, Description
																			
    }														
}
#							}
}
										
New-Alias -name CGM -value Compare-GroupMembership									
Export-ModuleMember Compare-GroupMembership -Alias CGM