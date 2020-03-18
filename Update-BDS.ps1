Param(

   [Parameter(Mandatory=$true)]
   [string]$BdsUrl,
   [Parameter(Mandatory=$true)]
   [string]$BdsLocalPath,
   [Parameter(Mandatory=$true)]
   [string]$WwwOwnerUsername
)

$ErrorActionPreference = "Stop";
Set-Location $PSScriptRoot;

& git pull

# Shut down server
Write-Host "Stopping kestrel...";
& service kestrel-freshstartprod stop

# Delete old backup
Write-Host "Cleaning up old backup...";
Remove-Item -Path "$($BdsLocalPath)_BACKUP";

# Backup dir
Write-Host ""Backing up current version;
Move-Item -Path "$BdsLocalPath" -Destination "$($BdsLocalPath)_BACKUP";

# Download new version
Write-Host "Downloading new version from:$BdsUrl...";
Remove-Item bds_update.zip
& wget -O bds_update.zip $BdsUrl
Write-Host "Unzipping...";
& unzip bds_update.zip

Move-Item -Path bds_update -Destination $BdsLocalPath;

# Copy tweaks
Write-Host "Copying tweaks...";
Copy-Item -Path "$PSScriptRoot/BDS/*" -Destination $BdsLocalPath;

Write-Host "Copying world to new location..."
Copy-Item -Path "$($BdsLocalPath)_BACKUP/worlds" -Destination "$BdsLocalPath"

# Set Permissions
Write-Host "Setting permissions";
& chown $WwwOwnerUsername -R $BdsLocalPath
& chmod -R +rwx $BdsLocalPath 

# Start server
Write-Host "Starting kestrel...";
& service kestrel-freshstartprod start
