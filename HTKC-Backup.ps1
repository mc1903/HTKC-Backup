<#
The Official Home for this Project is https://github.com/mc1903/HTKC-Backup

Distibution/License:

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


This script has been tested with the following applications/versions:

    HyTrust KeyControl version 4.2, build 13635
    HyTrust KeyControl version 4.2.1, build 14464
    
Version 1.00 - Martin Cooper 09/09/2018

    Initial Release.
    
#>

#Set Working Variables Below
$BackupTo = "C:\Users\Administrator\OneDrive\My PowerShell\General\HyTrust KeyControl Backup\Backups\"
$DaysToKeepBackups = "30"
$HTKCServerFQDN = "mc-htkc-v-101.momusconsulting.com"
$HTKCBackupUser = "backup"
$HTKCBackupPwd = "Pa55word5!"

#Please DO NOT change anything below this line!

#Delete an expired backups files
$TodaysDate = Get-Date
$DeleteByDate = $TodaysDate.AddDays(-$DaysToKeepBackups)
Get-ChildItem $BackupTo | Where-Object { $_.LastWriteTime -lt $DeleteByDate } | Remove-Item

#Create Pre-Authentication Header
$PreAuthHeader=@{}
$PreAuthHeader.add("username","$HTKCBackupUser")
$PreAuthHeader.add("password","$HTKCBackupPwd")

#By default KeyControl 4.2 now only accepts TLS 1.2 connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Authenticate with the KeyControl server & Get the Session Token
$GetPreAuthToken = Invoke-Restmethod -method POST -Uri "https://$HTKCServerFQDN/v5/kc/login/" -body $PreAuthHeader

#Create Valid Authentication Session Token
$SessionAuthToken=@{}
$SessionAuthToken.add("Auth-Token",$GetPreAuthToken.access_token)

#Create Body Parameters
$BodyParameters=@{}
$BodyParameters.add("verify","false")

#Generate a new Backup File on the KeyControl server
Invoke-Restmethod -method POST -Uri "https://$HTKCServerFQDN/v5/system_backup/" -headers $SessionAuthToken -body $BodyParameters | Out-Null

#Get the new Backup Filename from the KeyControl server
$HTKCBUFilenameReq = Invoke-WebRequest -method GET -Uri "https://$HTKCServerFQDN/v5/system_backup/" -headers $SessionAuthToken -body $BodyParameters
$HTKCBUFilename = $HTKCBUFilenameReq.Headers.'Content-Disposition'.Split('=')[1]
$HTKCBUFilePath = $BackupTo + "" + $HTKCBUFilename

#Download the new Backup File from the KeyControl server
Invoke-Restmethod -method GET -Uri "https://$HTKCServerFQDN/v5/system_backup/" -headers $SessionAuthToken -body $BodyParameters -OutFile $HTKCBUFilePath | Out-Null

#Logout so the Session Token is no longer useable
Invoke-Restmethod -method POST -Uri "https://$HTKCServerFQDN/v5/kc/logout/" -headers $SessionAuthToken | Out-Null

#Clear ALL Variables out of memory
Remove-Variable -Name * -ErrorAction SilentlyContinue