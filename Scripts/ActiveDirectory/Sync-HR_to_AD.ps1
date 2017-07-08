<#
     .SYNOPSIS
        Syncs user properties from HR SQL into AD.
     .DESCRIPTION
        Syncs user attributes from HR SQL into AD. Can join on either SamAccountName or Employeeid.
     .PARAMETER  Server
        Remote DC to sync against.
     .PARAMETER  Properties
<<<<<<< HEAD
          User's properties to sync. Sync all or a subset. Add new properties to validate set if needed. 
=======
        User's properties to sync. Add new properties to validate set if needed. 
>>>>>>> 65305ed9a19fca6d3e6ec2623775adfa17c629ea
     .PARAMETER	JoinOn
	Compare SamAccountName or EmployeeID.      
     .PARAMETER	SQLServer
	SQL server to import data from.
     .PARAMETER	Database
	SQL server database containing data.
     .PARAMETER	Credential
	Remote AD credentials.
     .PARAMETER	ShowProgress
	Show progress if running from command line.          
     .EXAMPLE
	PS C:\> .\Sync-HR_to_AD.ps1 -properties Title, Department, Office, Enabled -Credential $creds
	Syncs users from HR into AD with default remote server.
     .NOTES
<<<<<<< HEAD
          Written by Aaron Ticehurst 7/4/2017. 
          
=======
     	Written by Aaron Ticehurst 7/4/2017. 
>>>>>>> 65305ed9a19fca6d3e6ec2623775adfa17c629ea
#>

[cmdletbinding(SupportsShouldProcess = $True)]
param(
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 0)]
    [String]$Server = 'ticehurst.local',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 1)]
    [ValidateSet("Title", "Department", "Office", "Enabled", "EmployeeID", "Givenname", "Surname", "Displayname", "Company")] 
    [string[]]$Properties,
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 2)]
    $RemoteOU = 'OU=ii,OU=People,OU=Staff,DC=ticehurst,DC=local',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 3)]
    [ValidateSet("SamAccountName", "EmployeeID")] 
    [string]$JoinOn = 'SamAccountName',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 4)]
    [String]$SQLServer = 'sql2',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 5)]
    [String]$Database = 'ITS',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 6)]
    [pscredential]$Credential,
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 7)]
    [Switch]$ShowProgress = $False
)

#requires -module ActiveDirectory

if (-not (Test-Path c:\Logs\HR_Sync)) {New-Item -Path c:\Logs\HR_Sync -ItemType Directory}
$LogFolder = "c:\Logs\HR_Sync"
$LogFile = "HR_Sync.$(Get-date -format ddMMyyyyhhmmss).log"
$LogPath = Join-Path -path $LogFolder -ChildPath $LogFile
$NewLog = New-Item -Path $LogPath -ItemType File 
Write-Verbose "LogFile: $LogPath on $env:ComputerName"

[int]$JoinedUsers = 0

#Change query to match what ever table is needed
#Need to Transform SQL columns to match against Active Directory properties
$Query = @'
USE [ITS]
SELECT USERNAME AS [SamAccountName],
CONCAT(firstName,  ' ', Surname) DisplayName, 
Firstname AS [GivenName],
Surname,
Company,
STAFF_ID AS [EmployeeID], 
POSITION_TITLE AS [Title],
LOCATION AS [Office],
Dept AS [Department],
CASE 
       WHEN Active = 0 THEN 'False'
            ELSE 'True'
       END AS 'Enabled'
FROM tblHRIS_STAFF
'@	
[string]$ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$command = $connection.CreateCommand()
			    
$command.CommandText = $query
$adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
$dataset = New-Object -TypeName System.Data.DataSet
$adapter.Fill($dataset) | Out-Null
$SQLUsers = $dataset.Tables[0] 
$connection.Close()   

Write-Verbose ($SQLUsers | Measure-Object).Count             
$RemoteDCUsers = @()

$RemoteDCUsers = get-aduser -Filter {$JoinOn -like "*"} -SearchBase $RemoteOU -server $Server -Credential $Credential -Properties $Properties 
Write-Verbose $RemoteDCUsers.count

If ($SQLUsers -and $RemoteDCUsers) {

    [INT]$RemoteUserCount = $RemoteDCUsers.Count
    [INT]$CountUser = 0
    $User_Property_Hash = New-Object System.Collections.Hashtable -ArgumentList $Properties.count

    Foreach ($RemoteDCUser in $RemoteDCUsers) {
        #Start-Sleep -Seconds 1
        If ($ShowProgress) {
            $CountUser++ 
            Write-Progress -Activity "Syncing users" -Status "Checking $CountUser of $RemoteUserCount, $($RemoteDCUser.SamAccountName)" -PercentComplete ($CountUser / $RemoteUserCount * 100)
        }
        $MatchedHRUser = $null
        If ($JoinOn -eq 'SamAccountName' ) {  $MatchedHRUser = $SQLUsers.Where( { $_.SamAccountName -eq $RemoteDCUser.SamAccountName })}
        If ($JoinOn -eq 'EmployeeID' ) {  $MatchedHRUser = $SQLUsers.Where( { $_.EmployeeID -eq $RemoteDCUser.EmployeeID })}

        If ($MatchedHRUser) {
            
            $JoinedUsers++
                                   
            #Write-Verbose $RemoteDCUser.SamAccountname
            #Write-Verbose $MatchedHRUser.SamAccountname 
            Foreach ($Property in $Properties) { 
                If ($MatchedHRUser.$Property -ne $RemoteDCUser.$Property -and $Property -ne 'Enabled') {
                               
                    Write-output "$($MatchedHRUser.SamAccountName) -> $($RemoteDCUser.Samaccountname) Set $Property from $($RemoteDcUser.$Property) to $($MatchedHRUser.$Property)" | out-file $LogPath -Append
                    If ($MatchedHRUser.$Property -match '^$') {$User_Property_Hash.Add($Property, $Null)}  
                    Else {$User_Property_Hash.Add($Property, $MatchedHRUser.$Property)}
                }
                #Active status needs to be handled separately due to type mismatch.
                If ($MatchedHRUser.$Property -ne $RemoteDCUser.$Property -and $Property -eq 'Enabled') {
                                   
                    Write-output "$($MatchedHRUser.SamAccountName) -> $($RemoteDCUser.Samaccountname) Set $Property from $($RemoteDcUser.$Property) to $($MatchedHRUser.$Property)" | out-file $LogPath -Append
                    [boolean]$status = if ($MatchedHRUser.$Property -eq 'false') {$False}
                    Else {$True}
                    $User_Property_Hash.Add($Property, $status)
                } 

                       
            }
            If ($User_Property_Hash.count -gt 0) { 
                Write-Verbose $RemoteDCUser.Samaccountname 
                Set-ADUser -Identity $RemoteDCUser.Samaccountname -Credential $Credential -server $Server @User_Property_Hash 
            }
            $User_Property_Hash.Clear()
        }
    }
}
Write-Output "Number of users joined: $JoinedUsers" | out-file $LogPath -Append
Write-Verbose "Log cleanup"

<<<<<<< HEAD
Get-ChildItem -path $LogFolder | Where-Object {$_.LastWriteTime -le ((get-date).AddDays(-7))} | remove-item -recurse 
=======
Get-ChildItem -path $LogFolder | where {$_.LastWriteTime -le ((get-date).AddHours(-2))} | remove-item -recurse 
>>>>>>> 65305ed9a19fca6d3e6ec2623775adfa17c629ea
