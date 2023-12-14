# Run the java -version command and capture the output
$version = Get-Command java | Select-Object Version

# Display the extracted information
Write-Host "Java Version: $version.Version"

