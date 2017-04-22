<#
     .SYNOPSIS
        Syncs user properties from HR SQL into AD.
     .DESCRIPTION
        Syncs user attributes from HR SQL into AD. Can join on either SamAccountName or Employeeid.
     .PARAMETER  Server
        Remote DC to sync against.
     .PARAMETER  Properties
        User's properties to sync. Add new properties to validate set if needed. 
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
     	Written by Aaron Ticehurst 7/4/2017. 
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
    [bool]$ShowProgress = $False
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
$Query = @'
USE [ITS]
SELECT *
FROM tblHRIS_Staff
'@	
[string]$ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$command = $connection.CreateCommand()
			    
$command.CommandText = $query
$adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
$dataset = New-Object -TypeName System.Data.DataSet
$adapter.Fill($dataset) | Out-Null
$Users = $dataset.Tables[0] 
$connection.Close()   

#Need to Transform SQL columns to compare against Active Directory
$LocalDCUsers = Write-output $Users | Select @{n = 'DisplayName'; e = {"$($_.firstName)" + " " + "$($_.Surname)"}}, @{n = 'SamAccountName'; e = {$_.Username}}, @{n = 'Enabled'; e = {if ($_.Active -eq 0) {'False'}
        Else { 'True'}}
}, `
                @{n = 'EmployeeID' ; e = {$_.STAFF_ID}}, @{n = 'Title' ; e = {$_.POSITION_TITLE}}, @{n = 'Office' ; e = {$_.LOCATION}}, @{n = 'Department' ; e = {$_.Dept}}, @{n = 'GivenName'; e = {$_.FirstName}}, Surname, Company  
#Clear the SQL query variable to free memory as no longer needed
Clear-Variable Users
Write-Verbose $LocalDCUsers.count              
$RemoteDCUsers = @()

$RemoteDCUsers = get-aduser -Filter {$JoinOn -like "*"} -SearchBase $RemoteOU -server $Server -Credential $Credential -Properties $Properties 
Write-Verbose $RemoteDCUsers.count

If ($LocalDCUsers -and $RemoteDCUsers) {

    [INT]$RemoteUserCount = $RemoteDCUsers.Count
    [INT]$CountUser = 0
    $User_Property_Hash = New-Object System.Collections.Hashtable -ArgumentList $Properties.count

    Foreach ($RemoteDCUser in $RemoteDCUsers) {
        If ($ShowProgress) {
            $CountUser++ 
            Write-Progress -Activity "Syncing users" -Status "Checking $CountUser of $RemoteUserCount, $($RemoteDCUser.SamAccountName)" -PercentComplete ($CountUser / $RemoteUserCount * 100)
        }
        $MatchedHRUser = $null
        If ($JoinOn -eq 'SamAccountName' ) {  $MatchedHRUser = $LocalDCUsers.Where( { $_.SamAccountName -eq $RemoteDCUser.SamAccountName })}
        If ($JoinOn -eq 'EmployeeID' ) {  $MatchedHRUser = $LocalDCUsers.Where( { $_.EmployeeID -eq $RemoteDCUser.EmployeeID })}

        If ($MatchedHRUser) {
            
            $JoinedUsers++
                                   
            Write-Verbose $RemoteDCUser
            Write-Verbose "$($MatchedHRUser)"
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
                Write-Verbose $User_Property_Hash                            
                Set-ADUser -Identity $RemoteDCUser.Samaccountname -Credential $Credential -server $Server @User_Property_Hash 
            }
            $User_Property_Hash.Clear()
        }
    }
}
Write-Output "Number of users joined: $JoinedUsers" | out-file $LogPath -Append
Write-Verbose "Log cleanup"

Get-ChildItem -path $LogFolder | where {$_.LastWriteTime -le ((get-date).AddHours(-2))} | remove-item -recurse 
