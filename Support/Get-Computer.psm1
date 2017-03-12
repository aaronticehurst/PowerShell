Function Get-Computer {

    #Requires -version 3


    <#
     .SYNOPSIS
          Gets local or remote computer statistics primarily using WMI.
     .DESCRIPTION
          Used to retrieve general computer stats and other interesting information. Details retrieved include current logged on user (note it will be blank for VDI users as they are not techically logged on but have RDP'd in),
		  Some details returned include Computer Serial number, IP address, mac address, hard drive space used, last boot up time, local and regional details. Primarily uses WMI to retrieve results.
     .PARAMETER  ComputerName
          The Computer that you are targeting.
     .EXAMPLE
	 	  PS C:\scripts> Get-Computer

			cmdlet Get-Computer at command pipeline position 1
			Supply values for the following parameters:
			ComputerName: COMPUTERNAME
			Call script name but leave out the computer name and you will be asked to supply the computer name.
	
	 .EXAMPLE
	
          PS C:\> Get-Computer COMPUTERNAME
		  Call script name, followed by the computer you are looking at.
     .NOTES
          Written by Aaron Ticehurst 14/01/2010.		  
		  Modification 4/07/2010: Added Last Boot Up Time and renamed script from Get-ComputerStats.ps1 to Get-ComputerStat.ps1 to follow PowerShell convention.
		  Modification 19/08/2010: Added help function and ComputerName parameter, some additional clean up.
		  Modification 8/10/2010: Renamed Script to Get-ComputerDetails.
		  Modification 12/11/2010: Added Method for pulling usernames from VDI and logged on sessions. Renamed Script to Get-ComputerDetail. Some minor cleanup.
          Modification 31/5/2011: Renamed to Get-Computer.
          Modification: 5/2/2011: Added check for local admin and roaming profile checks.
          Modification 27/12/2013: Converted over to use CIM cmdlets.
#>


    param(

        [CmdletBinding()]
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [string]$ComputerName
				)	


    #Get computer system stats.
    Function GetStats {
        $sessionopt = New-CimSessionOption -Protocol Dcom
        $session = New-CimSession -computername $ComputerName -SessionOption $sessionopt
        Write-Host -foregroundcolor yellow "Computer Statistics for"$ComputerName

        Get-Ciminstance win32_bios -CimSession $Session 

        $GetProcessor = Get-Ciminstance -CimSession $Session -Query 'Select Name, MaxClockSpeed from Win32_Processor'
        Write-host "CPU: `t`t`t" $GetProcessor.Name
        Write-host "CPU Speed: `t`t" $GetProcessor.MaxClockSpeed "MHZ"
        Write-host

        $GetComputerSystem = (Get-Ciminstance -CimSession $Session win32_computerSystem | select Domain, Manufacturer, Model, Name, UserName, DaylightInEffect)
        #$GetUserName = $GetComputerSystem.UserName

        $GetTotalPhysicalMemory = (Get-Ciminstance Win32_PhysicalMemory -CimSession $Session | measure-object Capacity -sum).sum/1mb
        $AvailableRam = (Get-Ciminstance -CimSession $Session Win32_PerfFormattedData_PerfOS_Memory | select AvailableMBytes)

        Write-Host "Domain: `t`t"  $GetComputerSystem.domain
        Write-Host "Manufacturer: `t`t" $GetComputerSystem.Manufacturer
        Write-Host "Model: `t`t`t" $GetComputerSystem.Model
        Write-Host "Name: `t`t`t" $GetComputerSystem.Name
        Write-Host "Total Physical Memory: `t"$GetTotalPhysicalMemory "MB"
        Write-Host "Ram Available: `t`t"$AvailableRam.AvailableMBytes "MB"
		
		

        #Computer OS Version and service pack details.
        $GetOSSystem = (Get-Ciminstance -CimSession $Session Win32_OperatingSystem)
        $GetOSName = ([String]$GetOSSystem.name)
        $Split = $GetOSName.indexof("|")
        $strOS = $GetOSName.substring(0,$Split)

        Write-Host "Operating System: `t" $strOS 
        Write-Host "Service Pack: `t`t" $GetOSSystem.CSDVersion
        Write-Host

        #Logged in users	
        $GetUserName = Get-Ciminstance win32_process -CimSession $Session |where{$_.name -eq "explorer.exe"}
        $Users = ($GetUserName | Foreach {Invoke-CimMethod -InputObject $_ -CimSession $session -method getowner})
        foreach ($user in $Users){

            Write-host "Current User logged in:  $($user.domain)\$($user.user)"
            $computer = [ADSI]("WinNT://" + $ComputerName + ",computer")
            $Group = $computer.psbase.children.find("Administrators")
            $members= $Group.psbase.invoke("Members") | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
            if ($members -contains (($user.User) -replace "\w*\\","") ){
		
                Write-Host "Direct Local Admin: `t" $true
            }
            else {
                Write-Host "Direct Local Admin: `t" $false
            }	
                                	
            If ( $strOS -match 'Microsoft Windows 7' -and $GetUserName){		
                $UserProfile = Get-Ciminstance Win32_UserProfile -CimSession $Session | where {$_.LocalPath -match (($user.user) -replace "\w*\\","")}

                Switch -regex ($UserProfile.Status) {
                    '0' {
                        $Status = 'Default' ; Break
                    }
                    '1' {
                        $Status = 'Temporary' ; Break
                    }
                    '2' {
                        $Status = 'Roaming' ; Break
                    }
                    '4' {
                        $Status = 'Mandatory' ; Break
                    }
                    '8' {
                        $Status = 'Corrupted' ; Break
                    }
                }	
                Write-Host "Roaming Path: `t`t" $UserProfile.RoamingPath
                Write-Host "Profile Status: `t" $Status

                If ($UserProfile.LastDownloadTime) {
                    Write-Host "Last Download Time: `t" $UserProfile.LastDownloadTime
                }
                Else {
                    Write-Host "Last Download Time: `t" 
                }

                If ($UserProfile.LastUploadTime) {									
                    Write-Host "Last Upload Time: `t" $UserProfile.LastUploadTime
                }
                Else {
                    Write-Host "Last Upload Time:" 
                }

                If ($UserProfile.LastUseTime) {
                    Write-Host "Last Use Time: `t`t" $UserProfile.LastUseTime
                }
                Else {
                    Write-Host "Last Use Time:"	
                }						
            }
            Write-Host	
        }
        #Get's Computer Hard Drive stats   
        $Device = (Get-Ciminstance Win32_logicalDisk -CimSession $Session | where-object {$_.drivetype -eq 3} )

        Foreach ($Device1 in $Device) {

            $Drive = $Device1.DeviceID
            write-host "Drive details for"$Drive

            $Size = "{0:N2}" -f ($Device1.size/1GB)
            Write-host "Size of Hard drive: `t"$Size "GB" 
		
            $FreeSpace = "{0:N2}" -f ($Device1.Freespace/1GB)  
            write-host "Freespace on drive: `t"$FreeSpace "GB"
			
            $PercentageFree = "{0:N2}" -f ($FreeSpace/$Size*100)
            Write-Host "Percentage free: `t" $PercentageFree "%"
	
        }
        write-host

        #Get Network stats.
        $GetNetwork = (Get-Ciminstance Win32_NetworkAdapterConfiguration -CimSession $Session | where-object {$_.ipEnabled -match "True"} )
        foreach($GetNetworkConfig in $GetNetwork) {
            $Adapter = $GetNetworkConfig.Description
            $IPAddress = $GetNetworkConfig.ipaddress
            $MacAddress = $GetNetworkConfig.MacAddress
            Write-host "Adapter: `t`t"$Adapter
            Write-host "IP address: `t`t"$IPAddress
            Write-host "Mac Address: `t`t"$MacAddress
            Write-host
			
        }
    
    
        #Get Date and Time Stats.
        Write-Host "Last Boot Up Time: `t"$GetOSSystem.LastBootUpTime
        
        $GetDate = Get-CimInstance win32_localtime -CimSession $Session
        $LocalTime = "$($GetDate.day)/$($GetDate.Month)/$($GetDate.year) $($GetDate.hour):$($GetDate.Minute)"
        Write-Host "Local Time: `t`t $(get-date $LocalTime -f g)"
				
        

        $GetTime = (Get-Ciminstance -CimSession $Session Win32_TimeZone| select Caption)
        $TimeZone = ($GetTime.caption)
        $DayLightSaving = ($GetComputerSystem.DaylightInEffect)
        Write-host "Time zone: `t`t"$TimeZone

        Switch ($DayLightSaving) {
            "TRUE"   {
                Write-host -foregroundcolor yellow "`t`t`t Daylight Saving is on this computer"
            }
            "FALSE"  {
                Write-host "`t`t`t Daylight Saving is not on this computer"
            }
            Default  {
                Write-host "`t`t`t Daylight Saving is not on this computer"
            }
        }
        Remove-CimSession $session   
    }

    #Test to see if script is able to connect to the requested computer.
    $Test = Test-Connection -ComputerName $ComputerName -quiet -count 1
    

    If ($ComputerName -eq "."){
        GetStats
    }
    Elseif  ($Test -eq "True"){
        GetStats
    }
    Else {
        Write-host "Unable to connect to the requested computer."
    }
    
}
	
New-Alias -name gic -value Get-Computer
Export-ModuleMember -Function Get-Computer -Alias gic