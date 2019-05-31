<#
Function Examples that can be imported using PowerShell Dot Sourcing

Assumign you saved this script to the C:\Scripts Directory this is how you would ingest the scripts. 

set-location -path C:\Scripts
Now we use Dot Sourcing to import all the functions into global memory. 

. .\Write-Functions.Ps1 

#>
function write-GreenMessage {
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$false)]
    [string]$Message
    )
    $originState = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = "Green"
    Write-Output -inputobject $Message
    $Host.UI.RawUI.ForegroundColor = $originState
}

function write-YellowMessage {
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$false)]
    [string]$Message
    )
    $originState = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    Write-Output -inputobject $Message
    $Host.UI.RawUI.ForegroundColor = $originState
}

function write-RedMessage {
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$false)]
    [string]$Message
    )
    $originState = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = "Red"
    Write-Output -inputobject $Message
    $Host.UI.RawUI.ForegroundColor = $originState
}