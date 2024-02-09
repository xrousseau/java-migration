# Purpose
This script purpose is to replace currently installed version of Oracle Java (JRE and JDK) and replace it with an equivalent OpenJDK version.
The script execution steps are :
1. Inventory the Oracle Java packages installed on a Windows desktop computer and identify the default Java version.
1. Install equivalent or closest upward LTS Open JDK versions. Ensure the same OpenJDK version is set as default to avoid breaking changes.
1. Uninstall Oracle Java packages
1. Simulate Oracle Java by recreating installation folders with Junction Paths pointing to the OpenJDK equivalent or closest LTS version.

# Dependencies
The script currently dependens on Eclipse Temurin OpenJDK packages in the Download folder. This needs to be adjusted for real life scenario.

# Java version equivalency
The script migrate to the closest LTS version of Java. For example, Java currently LTS versions are `8, 11, 17 and 21`.
For example, an Oracle Java 9 will be migrated to an OpenJDK 11.
The script will install to same package type i.e. JDK vs JRE.
