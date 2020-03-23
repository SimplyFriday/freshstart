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

# Backup dir
Write-Host ""Backing up current version;
if (Test-Path "$BdsLocalPath") {
   Remove-Item "$($BdsLocalPath)_BACKUP" -Force -Recurse;
} else {
   Write-Error "ERROR: '$BdsLocalPath' does not exist!";
   exit -1; 
}
Move-Item -Path "$BdsLocalPath" -Destination "$($BdsLocalPath)_BACKUP" -Force;

# Download new version
Write-Host "Downloading new version from:$BdsUrl...";

if (Test-Path bds_update.zip) {
   Remove-Item -Path bds_update.zip -Force;
}

if (Test-Path bds_update) {
   Remove-Item -Path bds_update -Recurse -Force;
}

& wget -O bds_update.zip $BdsUrl
Write-Host "Unzipping...";
& unzip bds_update.zip -d bds_update

Move-Item -Path bds_update -Destination $BdsLocalPath;

# Copy tweaks
Write-Host "Copying tweaks...";
Copy-Item -Path "$PSScriptRoot/BDS/*" -Destination $BdsLocalPath -Force -Recurse;

Write-Host "Copying world to new location..."
Copy-Item -Path "$($BdsLocalPath)_BACKUP/worlds" -Destination "$BdsLocalPath"

# Set Permissions
Write-Host "Setting permissions";
& chown $WwwOwnerUsername -R $BdsLocalPath
& chmod -R +rwx $BdsLocalPath 

# Start server
Write-Host "Starting kestrel...";
& service kestrel-freshstartprod start
