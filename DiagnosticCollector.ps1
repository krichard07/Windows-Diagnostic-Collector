$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$OS = Get-CimInstance Win32_OperatingSystem

$ComputerSystem = Get-CimInstance Win32_ComputerSystem
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$Uptime = New-TimeSpan -Start $OS.LastBootUpTime -End (Get-Date)

$ReportDirectory = Join-Path $PSScriptRoot "reports"

if (-not (Test-Path $ReportDirectory)) {
    New-Item -ItemType Directory -Path $ReportDirectory | Out-Null
}

$ReportFile = Join-Path $ReportDirectory "diagnostic_$Timestamp.txt"

$NetworkInfo = Get-NetIPConfiguration |
    Where-Object { $_.IPv4Address } |
    ForEach-Object {
        [PSCustomObject]@{
            Interface = $_.InterfaceAlias
            IPv4      = ($_.IPv4Address.IPAddress -join ", ")
            Gateway   = ($_.IPv4DefaultGateway.NextHop -join ", ")
            DNS       = ($_.DNSServer.ServerAddresses -join ", ")
        }
    } |
    Format-Table -AutoSize |
    Out-String

$DnsTestHost = "www.microsoft.com"

try {
    $DnsResult = Resolve-DnsName $DnsTestHost -Type A -ErrorAction Stop |
        Select-Object -First 1

    $DnsStatus = "PASS - $($DnsResult.IPAddress)"
}
catch {
    $DnsStatus = "FAIL - $($_.Exception.Message)"
}

$ConnectivityTarget = "8.8.8.8"

$PingResult = Test-Connection `
    -ComputerName $ConnectivityTarget `
    -Count 1 `
    -Quiet

if ($PingResult) {
    $ConnectivityStatus = "PASS"
}
else {
    $ConnectivityStatus = "FAIL"
}

$GpResult = gpresult /r 2>&1 | Out-String

$EventLogStart = (Get-Date).AddHours(-24)

try {
    $EventLogErrors = Get-WinEvent -FilterHashtable @{
        LogName   = @("System", "Application")
        Level     = @(1, 2)
        StartTime = $EventLogStart
    } -MaxEvents 50 -ErrorAction Stop |
        Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName, Message |
        Format-List |
        Out-String
}
catch {
    $EventLogErrors = "Unable to read Event Log: $($_.Exception.Message)"
}

$PendingReboot = $false

$RebootKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
)

foreach ($Key in $RebootKeys) {
    if (Test-Path $Key) {
        $PendingReboot = $true
    }
}

$PendingFileRename = Get-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
    -Name "PendingFileRenameOperations" `
    -ErrorAction SilentlyContinue

if ($PendingFileRename) {
    $PendingReboot = $true
}

if ($PendingReboot) {
    $PendingRebootStatus = "YES"
}
else {
    $PendingRebootStatus = "NO"
}

$SccmService = Get-Service -Name CcmExec -ErrorAction SilentlyContinue

if ($SccmService) {
	try {
		$SccmClient = Get-CimInstance `
			-Namespace "root\ccm" `
			-ClassName SMS_Client `
			-ErrorAction Stop

		$SccmSite = Invoke-CimMethod `
			-Namespace "root\ccm" `
			-ClassName SMS_Client `
			-MethodName GetAssignedSite `
			-ErrorAction Stop

		$SccmDetected = "YES"
		$SccmServiceStatus = $SccmService.Status
		$SccmClientVersion = $SccmClient.ClientVersion
		$SccmWmiStatus = "Available"
		$SccmSiteCode = $SccmSite.sSiteCode
	}
	catch {
		$SccmDetected = "YES"
		$SccmServiceStatus = $SccmService.Status
		$SccmClientVersion = "Unable to retrive"
		$SccmWmiStatus = "Unavailable"
		$SccmSiteCode = "Unable to retrieve"
	}
}
else {
	$SccmDetected = "NO"
	$SccmServiceStatus = "Not installed"
	$SccmClientVersion = "N/A"
	$SccmWmiStatus = "N/A"
	$SccmSiteCode = "N/A"
	}

$Report = @(
    "Windows Diagnostic Collector"
    "Run time: $Timestamp"
    "Computer name: $env:COMPUTERNAME"
    "Windows: $($OS.Caption)"
    "Version: $($OS.Version)"
    "Build: $($OS.BuildNumber)"
    "RAM: $([math]::Round($ComputerSystem.TotalPhysicalMemory / 1GB, 2)) GB"
    "C: total space: $([math]::Round($Disk.Size / 1GB, 2)) GB"
    "C: free space: $([math]::Round($Disk.FreeSpace / 1GB, 2)) GB"
    "Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"
    ""
    "--- NETWORK CONFIGURATION ---"
    $NetworkInfo
    ""
    "--- DNS TEST ---"
    "Host: $DnsTestHost"
    "Result: $DnsStatus"
    ""
    "--- CONNECTIVITY TEST ---"
    "Target: $ConnectivityTarget"
    "Result: $ConnectivityStatus"
    ""
    "--- GROUP POLICY RESULT ---"
    $GpResult
    ""
    "--- EVENT LOG ERRORS - LAST 24 HOURS ---"
    $EventLogErrors
    ""
    "--- PENDING REBOOT ---"
    "Restart required: $PendingRebootStatus"
    ""
    "---SCCM CLIENT ---"
    "Client detected: $SccmDetected"
    "CmmExec service: $SccmServiceStatus"
    "Client version: $SccmClientVersion"
    "Assigned site: $SccmSiteCode"
    "WMI/CIM namespace: $SccmWmiStatus"
)

$Report | Tee-Object -FilePath $ReportFile

Write-Host ""
Write-Host "Report saved to:"
Write-Host $ReportFile
