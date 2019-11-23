$Volumes = Get-Disk | Where-Object Disknumber -NE 0 | Get-Partition | Get-Volume

$foregroundcolor = "green"


Write-Host `n"Select driveletter for backup..."`n

Function ShowDisk 
{
    Param(
        $VolumeData
    )
    Write-Host -NoNewLine "<" -foregroundcolor $foregroundColor
    Write-Host -NoNewLine "Label: $($VolumeData.FileSystemLabel)"
    Write-Host -NoNewLine ">" -foregroundcolor $foregroundColor
    Write-Host -NoNewLine "["
    Write-Host -NoNewLine $VolumeData.DriveLetter -foregroundcolor $foregroundColor
    Write-Host -NoNewLine "]"
}

foreach($Volume in $Volumes)
{
    Showdisk -VolumeData $Volume
}

Write-Host ""

$sel = Read-Host "Select backup (destination) driveletter "
$root = $sel + ":\"

$Disk0OSVolumes = (get-disk -Number 0 | Get-Partition | Get-Volume | Where-Object DriveLetter -NE $null).driveletter

$BackupName = Read-Host "Type the name of the backup (no spaces, only A-Z and 0-1, min 3 characters and max 15 characters) "

foreach($Disk0OSVolume in $Disk0OSVolumes)
{
	
	$Name = $BackupName + "-" + $Disk0OSVolume
	$CaptureFile = $root + $Name
	$CaptureVolume = $Disk0OSVolume+ ":\"
	if((Test-Path -Path $root) -eq $true)
	{
		Write-Host "Capture $CaptureVolume to $CaptureFile with the name $Name using DISM"
		DISM /Capture-Image /CaptureDir:$CaptureVolume /ImageFile:$CaptureFile /Name:$Name /Compress:MAX
	}
}

Read-Host "Press any key to continue"



