# 1. Install OpenJDK 
$downloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$pathToJDKMSI = $downloadsPath + "\OpenJDK17U-jdk_x64_windows_hotspot_17.0.8_7.msi"

$installCmd = "/i ""$($pathToJDKMSI)"" RebootYesNo=No /q"
Start-Process -FilePath "msiexec.exe" -ArgumentList $installCmd -Wait


# 2.  Retreive Oracle Java paths from registry to later reconstruct with junction path after uninstallation
$registryPath = "HKLM:\SOFTWARE\JavaSoft"
$javaHomeValues = @()

$javaHomeEntries = Get-ChildItem -Path $registryPath -Recurse | Get-ItemProperty | Where-Object { $_.PSObject.Properties.Name -contains 'JavaHome' }

foreach ($entry in $javaHomeEntries) {
    $javaHomeValue = $entry.JavaHome
    if ($javaHomeValue -notin $javaHomeValues) {
        $javaHomeValues += $javaHomeValue
    }
}

# 3. Save to file for extra security in case the script breaks
$javaHomeValues | Out-File -FilePath ".\javapath.txt"

# 4. Uninstall Oracle Java instances
$guidsArray = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Vendor -like "*Oracle*" -and $_.Name -like "*Java*" } | ForEach-Object { $_.IdentifyingNumber }
foreach ($guid in $guidsArray) {
    Write-Host "Attempting removal of $guid "
    $uninstallCmd = "/x `"$guid`" /qn"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
}

