.\helper.ps1

$jrePackages = @{
    "jre-8"  = "OpenJDK8U-jre_x64_windows_hotspot_8u392b08.msi"
    "jre-11" = "OpenJDK11U-jre_x64_windows_hotspot_11.0.21_9.msi"
    "jre-17" = "OpenJDK17U-jre_x64_windows_hotspot_17.0.9_9.msi"
    "jre-21" = "OpenJDK21U-jre_x64_windows_hotspot_21.0.1_12.msi"
    "jdk-8"  = "OpenJDK8U-jdk_x64_windows_hotspot_8u392b08.msi"
    "jdk-11" = "OpenJDK11U-jdk_x64_windows_hotspot_11.0.21_9.msi"
    "jdk-17" = "OpenJDK17U-jdk_x64_windows_hotspot_17.0.9_9.msi"
    "jdk-21" = "OpenJDK21U-jdk_x64_windows_hotspot_21.0.1_12.msi"
}

# Retreive Oracle Java paths from registry to later reconstruct with junction path after uninstallation
$registryPath = "HKLM:\SOFTWARE\JavaSoft"
$javaHomeValues = @()
$openJDKPackagesToInstall = @()

$javaHomeEntries = Get-ChildItem -Path $registryPath -Recurse | Get-ItemProperty | Where-Object { $_.PSObject.Properties.Name -contains 'JavaHome' }

foreach ($entry in $javaHomeEntries) {
    $javaHomeValue = $entry.JavaHome
    if ($javaHomeValue -notin $javaHomeValues) {
        $javaHomeValues += $javaHomeValue
    }
}

$javaHomeValues | Out-File -FilePath ".\javapath.txt"

# Get the default version installed
$version = Get-Command java | Select-Object Version


# 2. Install OpenJDK equivalent version to Oracle Java  
$javaHomeValues = Get-Content -Path ".\javapath.txt"
$downloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

foreach ($javaHomeValue in $javaHomeValues) { 
    $version = JavaVersion -Path $javaHomeValue
    $openJDKPackagesToInstall = $downloadsPath + "\" + $jrePackages[$version]
    Write-Host "Installing $openJDKPackagesToInstall"
    $installCmd = "/i ""$($openJDKPackagesToInstall)"" RebootYesNo=No /q"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $installCmd -Wait
    Write-Host "$openJDKPackagesToInstall installed"
}

Exit

# 3. Uninstall Oracle Java instances
$guidsArray = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Vendor -like "*Oracle*" -and $_.Name -like "*Java*" } | ForEach-Object { $_.IdentifyingNumber }
foreach ($guid in $guidsArray) {
    Write-Host "Attempting removal of $guid "
    $uninstallCmd = "/x `"$guid`" /qn"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
}

# Create Junction Path
$openJdkPath = "C:\Program Files\Eclipse Adoptium\jre-8.0.392.8-hotspot"

$javaHomeValues = Get-Content -Path ".\javapath.txt"

foreach ($javaHomeValue in $javaHomeValues) {
    New-Item -ItemType Junction -Path $javaHomeValue -Target $openJdkPath
}

