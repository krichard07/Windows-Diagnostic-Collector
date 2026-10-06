# Windows Diagnostic Collector

A PowerShell-based diagnostic tool for collecting common Windows troubleshooting information into a single timestamped report.

The project was created to reduce repetitive manual checks during workstation troubleshooting and provide a consistent diagnostic overview from a single script execution.

The collector performs read-only diagnostic checks and can be configured through PowerShell parameters without modifying the script itself.

## Features

The script collects:

- Windows edition, version and build number
- Computer name
- Installed RAM
- System drive size and available free space
- System uptime
- IPv4 network configuration
- Default gateway and DNS server information
- Configurable DNS resolution test
- Configurable network connectivity test
- Applied Group Policy information using `gpresult`
- Critical and Error events from the Windows Event Log
- Configurable Event Log lookback period
- Configurable maximum number of Event Log entries
- Pending reboot detection
- Local Microsoft Configuration Manager (SCCM) client diagnostics:
  - SCCM client detection
  - `CcmExec` service status
  - client version
  - assigned site code
  - WMI/CIM namespace availability
- Configurable report output directory
- Timestamped TXT report generation
- Built-in PowerShell help with usage examples

## Requirements

- Windows PowerShell 5.1 or later
- Appropriate local permissions for the requested diagnostic information
- Network access for DNS and connectivity tests

SCCM is optional. SCCM-specific information is collected only when the Configuration Manager client and the required WMI/CIM namespace are available.

## Usage

Run the script with the default settings:

```powershell
.\DiagnosticCollector.ps1
```

By default, the script:

- tests DNS resolution using `www.microsoft.com`
- tests connectivity using `8.8.8.8`
- collects Critical and Error events from the last 24 hours
- collects up to 50 Event Log entries
- saves reports to the `reports` directory

## Parameters

### DnsTestHost

Specifies the hostname used for the DNS resolution test.

Default:

```text
www.microsoft.com
```

Example:

```powershell
.\DiagnosticCollector.ps1 -DnsTestHost "localhost"
```

### ConnectivityTarget

Specifies the hostname or IP address used for the connectivity test.

Default:

```text
8.8.8.8
```

Example:

```powershell
.\DiagnosticCollector.ps1 -ConnectivityTarget "127.0.0.1"
```

### EventLogLookbackHours

Specifies how many hours the script looks back when collecting Critical and Error events.

Default:

```text
24
```

Example:

```powershell
.\DiagnosticCollector.ps1 -EventLogLookbackHours 12
```

### MaxEvents

Specifies the maximum number of Event Log entries included in the report.

Default:

```text
50
```

Example:

```powershell
.\DiagnosticCollector.ps1 -MaxEvents 25
```

### ReportDirectory

Specifies where generated diagnostic reports are saved.

By default, reports are written to the `reports` directory inside the project folder.

Example:

```powershell
.\DiagnosticCollector.ps1 -ReportDirectory ".\test-reports"
```

Multiple parameters can be combined:

```powershell
.\DiagnosticCollector.ps1 -EventLogLookbackHours 12 -MaxEvents 25
```

Custom DNS and connectivity targets can also be used together:

```powershell
.\DiagnosticCollector.ps1 -DnsTestHost "localhost" -ConnectivityTarget "127.0.0.1"
```

## Built-in Help

The script includes PowerShell comment-based help.

Display the full help:

```powershell
Get-Help .\DiagnosticCollector.ps1 -Full
```

Display usage examples:

```powershell
Get-Help .\DiagnosticCollector.ps1 -Examples
```

## Reports

Reports are saved as timestamped TXT files.

Default directory:

```text
reports/
```

Timestamped filenames prevent previous diagnostic reports from being overwritten.

The report contains separate sections for system information, networking, DNS, connectivity, Group Policy, Event Logs, reboot status and SCCM diagnostics.

## SCCM Diagnostics

When an SCCM client is available, the script checks local Configuration Manager information including:

- `CcmExec` service status
- SCCM client availability
- client version
- assigned site code
- required WMI/CIM namespace availability

If SCCM is not installed or the required namespace is unavailable, the script continues without terminating the rest of the diagnostic collection.

## Error Handling

Individual diagnostic checks are handled independently where possible.

A failed DNS lookup, connectivity test or unavailable SCCM component does not prevent the remaining diagnostic information from being collected.

This allows the report to remain useful even when part of the system or network environment is unavailable.

## Safety

The script is intended for diagnostic collection and performs read-only checks.

It does not:

- modify Windows configuration
- restart the computer
- install or remove software
- modify Group Policy
- change network settings
- modify SCCM configuration
- modify the registry

The registry is queried only for pending reboot detection.

## Privacy

Generated diagnostic reports may contain computer, network and system information.

Real production reports are excluded from the public repository through `.gitignore`.

Only synthetic or anonymized example data should be committed to the repository.