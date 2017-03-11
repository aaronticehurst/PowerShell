Function Copy-GroupMembership {

    #requires -version 3

    <#
     .SYNOPSIS
          Used to migrate AD groups from one object to another.
     .DESCRIPTION
          Used to migrate AD groups from one object to another.
     .PARAMETER  ObjectToMigrateFrom
          The object, user or group or computer that you want to copy it's group membership from.
     .PARAMETER  ObjectToMigrateTo
          The object, user or group or computer that you want to copy it's group membership from.
     .EXAMPLE
	  PS C:\Copy-GroupMembership.ps1 -ObjectToMigrateFrom GROUP1 -ObjectToMigrateTo GROUP1 -Verbose
	  Copies all the groups across in verbose mode, without verbose no output is displayed.
      .NOTES
          Written by Aaron Ticehurst 5/5/2016. 
		  		  
#>

    [CmdletBinding()]
    param (
      				
        [Parameter(Mandatory=$True,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
        [String]$ObjectToMigrateFrom,            
        [parameter(Mandatory=$True,
            ValueFromPipelineByPropertyName=$true,
            Position=2)]
        [String]$ObjectToMigrateTo
    )
    Begin {
        Import-Module ActiveDirectory 
    }
    Process {
        Write-Verbose "Copying groups from $($ObjectToMigrateFrom) to $($ObjectToMigrateTo)"
        $GroupsToMigrate = Get-ADPrincipalGroupMembership $ObjectToMigrateFrom
        
        foreach ($group in $GroupsToMigrate) { 
            #You may need to adjust the description to exempt list          
            if ((Get-ADGroup -Identity $group.samaccountname -Properties Description).Description -NotMatch '(FIM|HRIS|Domain Users)') {
                Write-Verbose "Adding $(($group).samaccountname) to $($ObjectToMigrateTo)"
                [PSCUSTOMOBJECT]@{
                    ObjectToMigrateFrom = $ObjectToMigrateFrom
                    ObjectToMigrateTo = $ObjectToMigrateTo
                    GroupCopied = ($group).samaccountname
                }


                Add-ADGroupMember -Identity $Group.Samaccountname -Members $ObjectToMigrateTo
            }
        }
    }
    End {
    }

}

Export-ModuleMember -Function Copy-GroupMembership