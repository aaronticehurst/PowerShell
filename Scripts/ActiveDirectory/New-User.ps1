<#
     .SYNOPSIS
       	Creates new users from HR SQL into AD.
     .DESCRIPTION
       	Creates new users from HR SQL into AD.
     .PARAMETER  Server
       	Remote DC to connect to.
     .PARAMETER	Database
	SQL server database containing data. 
     .PARAMETER	Credential
	Remote AD credentials.
     .PARAMETER	ShowProgress
	Show progress if running from command line.        
     .EXAMPLE
	PS C:\> .\New-User.ps1 -Credential $creds
	Creates new users in Active Directory
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
    [String]$StagingOU = "OU=ii,OU=People,OU=Staff,DC=ticehurst,DC=local",
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 2)]
    [String]$SQLServer = 'sql2',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 3)]
    [String]$Database = 'ITS',
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 4)]
    [pscredential]$Credential,
    [parameter(Mandatory = $False,
        ValueFromPipelineByPropertyName = $true,
        ValueFromPipeline = $true,
        Position = 5)]
    [bool]$ShowProgress = $False


)
if (-not (Test-Path c:\Logs\HR_Sync)) {New-Item -Path c:\Logs\HR_Sync -ItemType Directory}
$LogFolder = "c:\Logs\HR_Sync"
$LogFile = "HR_NewUser.$(Get-date -format ddMMyyyyhhmmss).log"
$LogPath = Join-Path -path $LogFolder -ChildPath $LogFile
$NewLog = New-Item -Path $LogPath -ItemType File 
Write-Verbose "LogFile: $LogPath on $env:ComputerName"

$Domain = ($env:USERDNSDOMAIN).ToLower()



$query = @'
SELECT * 
FROM tblHRIS_STAFF
order by Staff_id desc
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

#Used to test if user exists already
Function Get-User {
    
    param (
				
        [Parameter(Mandatory = $True,
            Position = 1)]
        [String]$Username
    )

    $DirectorySearcher = [adsisearcher]""
    $DirectorySearcher.Filter = "samaccountname=$Username"
    $Result = $DirectorySearcher.FindOne()
    $Result.properties.samaccountname

} 
[INT]$UsersCount = ($Users | Measure-Object).count                         
[INT]$CountUser = 0      
foreach ($User in $Users) {
    If ($ShowProgress) {
        $CountUser++ 
        Write-Progress -Activity "Adding new users" -Status "Checking $CountUser of $UsersCount, $($User.UserName)" -PercentComplete ($CountUser / $UsersCount * 100)
    }
    Write-Verbose "Checking $($user.Username)"    
    If (Get-User -Username "$($user.Username)" ) {Write-Verbose "$($user.Username) found, skipping"}
    Else {
        Write-Verbose "$($user.Username) not found, creating"
        $ComplexPassword = [System.Web.Security.Membership]::GeneratePassword(20, 10)
        If ( $user.FirstName -and $user.Surname) {
            $Initials = "$($user.FirstName)".Substring(0, 1)
            $Initials += "$($user.Surname)".Substring(0, 1)
            $Initials = $Initials.ToUpper()
        }
        Else {$Initials = ''}
        New-Aduser -SamAccountName "$($user.Username)" -Name "$($user.FirstName) $($User.Surname)" -DisplayName "$($user.FirstName) $($User.Surname)" -GivenName "$($user.FirstName)" -Surname "$($user.Surname)" -Office "$($user.Location)" -EmployeeID "$($User.Staff_ID)" -Initials $Initials `
            -UserPrincipalName "$($user.username+'@'+$Domain)" -AccountPassword (Convertto-securestring $ComplexPassword -asplainText -Force) -Enabled $true -Path $StagingOU -Department "$($User.Dept)" -Title "$($User.Position_Title)" -Company "$($User.Company)" -Credential $Credential -passthru | Select-Object -ExpandProperty  SamAccountName | out-file $LogPath -Append

    }
}
                    
