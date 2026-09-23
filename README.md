# Windows Diagnostic Collector

A PowerShell-based diagnostic tool for collecting common Windows troubleshooting information into a single timestamped report.

The project was created to reduce repetitive manual checks during workstation troubleshooting and provide a consistent diagnostic overview from a single script execution.

## Features

The script collects:

- Windows version and build number
- Computer name
- Installed RAM
- Disk size and available free space
- System uptime
- IPv4 network configuration
- Default gateway and DNS server information
- DNS resolution test
- Network connectivity test
- Applied Group Policy information (`gpresult`)
- Critical and Error events from the Windows Event Log from the last 24 hours
- Pending reboot detection
- Local Microsoft Configuration Manager (SCCM) client diagnostics:
  - SCCM client detection
  - `CcmExec` service status
  - Client version
  - Assigned site code
  - WMI/CIM namespace availability
- Timestamped TXT report generation

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or later
- Some diagnostic information may require appropriate local permissions
- SCCM information is collected only when the Configuration Manager client is installed

## Usage

Open PowerShell and navigate to the project directory:

```powershell
cd C:\Path\To\Windows-Diagnostic-Collector