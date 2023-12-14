# Rebuild Junction Path
$openJdkPath = "C:\Program Files\Eclipse Adoptium\jre-8.0.392.8-hotspot"

$javaHomeValues = Get-Content -Path ".\javapath.txt"

foreach ($javaHomeValue in $javaHomeValues) {
    New-Item -ItemType Junction -Path $javaHomeValue -Target $openJdkPath
}