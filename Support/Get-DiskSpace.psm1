Function Get-DiskSpace {

    <#
     .SYNOPSIS
          Gets disk space of a computer.
     .DESCRIPTION
            Gets disk space of a computer.
     .PARAMETER  ComputerName
          The Computer that you are targeting.
	 .EXAMPLE
	 	  PS C:\> Get-DiskSpace.ps1 -ComputerName TestComputer | ft -a
          Check diskspace of TestComputer
     .NOTES
          Written by Aaron Ticehurst 6/12/2012.
		  #>

    param(

        [CmdletBinding()]

        [parameter(ValueFromPipelineByPropertyName=$true,
            ValueFromPipeline=$true)]
        [alias("name")]
        [string[]]$ComputerName = $env:computername,
        [parameter(ValueFromPipelineByPropertyName=$true,
            ValueFromPipeline=$true)]
        [string]$Drive
				)	
    Begin {	
    }
    Process {

        Foreach ($Computer in $ComputerName ) {
            $Drive = $Drive + '%'
            #Get's Computer Hard Drive stats   
            $Device = get-wmiobject Win32_logicalDisk -ComputerName $Computer -Filter "drivetype = '3' and deviceID like `'$Drive`'" 

            Foreach ($Device1 in $Device) {

                $hash = @{ 
                    ComputerName = $Device1.__Server
                    Drive = $Device1.DeviceID
                    VolumeName = $device1.VolumeName
                    Size = [Math]::Round($Device1.size/1GB,0)
                    FreeSpace = [Math]::Round($Device1.Freespace/1GB,0)
                    PercentageFree = [Math]::Round($Device1.Freespace/$Device1.size*100,2)
			
			
                }
                $Object = New-Object PSObject -Property $hash
                Write-Output $Object | Select ComputerName, drive, VolumeName, Size, FreeSpace, PercentageFree
				
				
	
            }
        }
	
    }
		
    End {	
    }		

}
New-Alias -name GDS -value Get-DiskSpace
Export-ModuleMember Get-DiskSpace -Alias GDS