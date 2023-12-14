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

function PackageType {
    param (
        [String] $Path
    )

    if ($Path -match "jdk") {
        return "jdk"
    }

    return "jre"
}