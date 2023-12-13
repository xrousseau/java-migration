$downloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

# Remove any Java environement left over
$guidsArray = Get-CimInstance -ClassName Win32_Product | Where-Object { ($_.Vendor -like "*Oracle*" -and $_.Name -like "*Java*") -or $_.Vendor -like "*Eclipse Adoptium*"} | ForEach-Object { $_.IdentifyingNumber }

foreach ($guid in $guidsArray) {
    $uninstallCmd = "/x `"$guid`" /qn"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallCmd -Wait -NoNewWindow
}

# Clean junction path
Remove-Item -Path "C:\Program Files (x86)\Common Files\Oracle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files\Java" -Recurse -Force -ErrorAction SilentlyContinue

# install Oracle Java JRE
$pathToJRE = $downloadsPath + "\jre-8u202-windows-x64.exe"
Start-Process -FilePath $pathToJRE -ArgumentList "/s INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0" -Wait

# install Oracle Java JDK
$pathToJRE = $downloadsPath + "\jdk-8u202-windows-x64.exe"
Start-Process -FilePath $pathToJRE -ArgumentList "/s INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0" -Wait
