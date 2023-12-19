# Mapping of Java packages and their corresponding MSI files
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

# Mapping of java packages and their installation paths used for Junction path target
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

#Takes the Java install path to determines the closest onward LTS version of Java (e.g., 8, 11, 17, or 21) 
function JavaVersion {
    param (
        [String] $Path
    )

    $packageType = PackageType($Path)

    if ($Path -match "(?:jdk|jre)1\.(6|7|8)") {
        return $packageType + "-8"
    }
    elseif ($Path -match "(?:jdk|jre)-(9|10|11)") {
        return $packageType + "-11"
    }
    elseif ($Path -match "(?:jdk|jre)-(12|13|14|15|16)") {
        return $packageType + "-17"
    }
    return $packageType + "-21"
}

# Takes the Java install path to determine to Java package type (jre or jdk)
function PackageType {
    param (
        [String] $Path
    )

    if ($Path -match "jdk") {
        return "jdk"
    }

    return "jre"
}

# Retreives the Oracle Java paths from registry and saves it to a temporary file.
function Get-OracleJavaInstalledVersion {
    
    $registryPath = "HKLM:\SOFTWARE\JavaSoft"
    $javaHomeValues = @()

    $javaHomeEntries = Get-ChildItem -Path $registryPath -Recurse | Get-ItemProperty | Where-Object { $_.PSObject.Properties.Name -contains 'JavaHome' }

    foreach ($entry in $javaHomeEntries) {
        $javaHomeValue = $entry.JavaHome
        if ($javaHomeValue -notin $javaHomeValues) {
            $javaHomeValues += $javaHomeValue
            Write-Output "Javapath found -> $javaHomeValue" 
        }
    }

    # Find the default Java version installed
    $defaultVersion = (Get-Command java).Version.Major
    Write-Output "Default Java version is $defaultVersion" 

    # Ensure the defaut version at the end of the Array to be first in the PATH env variable
    $index = ($javaHomeValues | Where-Object {$_ -match "\\(jdk|jre)-$defaultVersion"} | Select-Object -Last 1)

    if ($null -ne $index) {
        $javaHomeValues = [System.Collections.ArrayList]$javaHomeValues
        $javaHomeValues.Remove($index)
        $javaHomeValues.Add($index)
    }

    # Save to file
    $javaHomeValues | Out-File -FilePath ".\javapath.txt"
    Write-Output "Data saved in .\javapath.txt " 
}

# Using the javapath.txt, install the OpenJDK equivalent version to Oracle Java
function Install-OpenJDK {
    $javaHomeValues = Get-Content -Path ".\javapath.txt"
    $downloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

    foreach ($javaHomeValue in $javaHomeValues) { 
        $version = JavaVersion -Path $javaHomeValue
        $openJDKPackagesToInstall = $downloadsPath + "\" + $jrePackages[$version]
        Write-Host "Installing $openJDKPackagesToInstall"
        $installCmd = "/i ""$($openJDKPackagesToInstall)"" ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome RebootYesNo=No /q"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $installCmd -Wait
        Write-Host "$openJDKPackagesToInstall installed"
    }
}

# Removes all all Oracle Java instances
function Uninstall-OracleJava {
    $guidsArray = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Vendor -like "*Oracle*" -and $_.Name -like "*Java*" } | ForEach-Object { $_.IdentifyingNumber }
    foreach ($guid in $guidsArray) {
        Write-Host "Attempting removal of $guid "
        $uninstallCmd = "/x `"$guid`" /qn"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
    }
}

# Creates Junction Path that mocks previous Oracle installation
function New-JunctionPaths {
    
    $javaHomeValues = Get-Content -Path ".\javapath.txt"

    foreach ($javaHomeValue in $javaHomeValues) {

        $version = JavaVersion -Path $javaHomeValue
        $openJdkPath = $openJDKPaths[$version]
        Write-Output "Creating Junction Path: $javaHomeValue -> $openJdkPath"
        New-Item -ItemType Junction -Path $javaHomeValue -Target $openJdkPath
    }
}

Get-OracleJavaInstalledVersion
Install-OpenJDK
Uninstall-OracleJava
New-JunctionPaths