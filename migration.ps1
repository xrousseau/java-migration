param (
    [Parameter(Mandatory=$true, HelpMessage="List of Oracle Java Product Identifying Numbers {GUID} to uninstall. Separated with a coma with or without blank spaces.")]
    [string] $guidList,
    [Parameter(Mandatory=$false, HelpMessage="Full path to the OpenJDK MSI to install after Oracle Java removal")]
    [string] $pathToMSI
)

# This script is compatible with Powershell 3.0 and upward.
#-pathToMSI "\\shared\OpenJDK17U-jdk_x64_windows_hotspot_17.0.8_7.msi"
#-guidsList "{26A24AE4-039D-4CA4-87B4-2F64180202F0}, {A1F643B4-A6F8-4B39-8913-03d7FB105359}"
# Get-CimInstance -ClassName Win32_Product | Where-Object { $_.IdentifyingNumber -like $guid }

function Test-AdminElevation {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return $isAdmin
}

# stop the script is right elevation is missing
if (-not (Test-AdminElevation)) {
    Write-Host "Run script with admin privileges."
    exit
}

# Oracle Java Installations removal
$guidsArray = $guidList.Replace(" ", "") -split ','
foreach ($guid in $guidsArray) {
    Write-Host "Attempting removal of $guid"
    $cimObjects = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.IdentifyingNumber -like $guid }

    if ($null -eq $cimObjects) {
        Write-Host "$guid not installed on this computer. Skipping uninstall."
    }
    else {
        $uninstallCmd = "/x `"$guid`" /qn"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
        Write-Host "$guid uninstalled."
    }
}

# OpenJdk installation
if ($pathToMSI -eq $null) {
    Write-Host "pathToMSI parameter was not supplied. IMPORTANT: OpenJDK will not be installed on this computer."
    Write-Host "End of execution."
    exit
}

if ($pathToMSI.Length -ne 0 -and (Test-Path $pathToMSI)) {
    Write-Host "Installing MSI from $($pathToMSI)"
    $installCmd = "/i ""$($pathToMSI)"" RebootYesNo=No /q"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $installCmd -Wait
}
else {
    Write-Host "Invalid MSI path $($pathToMSI). IMPORTANT: OpenJDK will not be installed on this computer."
}
