. .\helper.ps1

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


$openJDKPaths = @{
    "jre-8" = "C:\Program Files\Eclipse Adoptium\jre-8.0.392.8-hotspot"
    "jre-11" = "C:\Program Files\Eclipse Adoptium\jre-11.0.21.9-hotspot"
    "jre-17" = "C:\Program Files\Eclipse Adoptium\jre-17.0.9_9-hotspot"
    "jre-21" = "C:\Program Files\Eclipse Adoptium\jre-11.0.21.9-hotspot"
    "jdk-8" = "C:\Program Files\Eclipse Adoptium\jdk-8.0.392.8-hotspot"
    "jdk-11" = "C:\Program Files\Eclipse Adoptium\jdk-11.0.21.9-hotspot"
    "jdk-17" = "C:\Program Files\Eclipse Adoptium\jdk-17.0.9_9-hotspot"
    "jdk-21" = "C:\Program Files\Eclipse Adoptium\jdk-21.0.1_12-hotspot"
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

# Find the default Java version installed
$version = (Get-Command java).Version.Major

# Move defaut version at the end of the Array
$index = ($javaHomeValues | Where-Object {$_ -match "\\(jdk|jre)-$version"} | Select-Object -Last 1)

if ($null -ne $index) {
    $javaHomeValues = [System.Collections.ArrayList]$javaHomeValues
    $javaHomeValues.Remove($index)
    $javaHomeValues.Add($index)
}

# Save to file for recovery needs
$javaHomeValues | Out-File -FilePath ".\javapath.txt"

# Install OpenJDK equivalent version to Oracle Java  
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

# Uninstall all Oracle Java instances
$guidsArray = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Vendor -like "*Oracle*" -and $_.Name -like "*Java*" } | ForEach-Object { $_.IdentifyingNumber }
foreach ($guid in $guidsArray) {
    Write-Host "Attempting removal of $guid "
    $uninstallCmd = "/x `"$guid`" /qn"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
}

# Create Junction Path to mock previous Oracle installation
$javaHomeValues = Get-Content -Path ".\javapath.txt"

foreach ($javaHomeValue in $javaHomeValues) {

    $version = JavaVersion -Path $javaHomeValue
    $openJdkPath = $openJDKPaths[$version]
    New-Item -ItemType Junction -Path $javaHomeValue -Target $openJdkPath
}