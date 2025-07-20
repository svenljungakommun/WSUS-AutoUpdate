# WSUS-AutoUpdate.ps1

## 🔧 Overview

`WSUS-AutoUpdate.ps1` is a PowerShell-based automation script designed for **controlled, unattended, and fully logged Windows update installation** in WSUS-integrated environments. It supports production-grade logging via `PSWriteSyslog`, outputs structured JSON via TCP syslog, and manages reboots conditionally.

---

## 📦 Features

- Fully automatic WSUS update scanning and installation
- JSON syslog logging over TCP (default: `127.0.0.1:514`)
- Graceful error handling and result reporting
- Conditional reboot based on update requirements
- Designed for scheduled execution (e.g. Task Scheduler)
- Integrates with SIEM and log analytics via structured output

---

## 🖥 Prerequisites

| Component              | Requirement                         |
|------------------------|-------------------------------------|
| PowerShell             | Version 3 or later                  |
| Module                 | `PSWindowsUpdate`                   |
| Logging Destination    | Syslog server accepting TCP+JSON   |

Install PSWindowsUpdate:

```powershell
Install-Module PSWindowsUpdate -Force
````

---

## 🚀 Usage

### 🔹 Run the script manually

```powershell
.\WSUS-AutoUpdate.ps1
```

### 🔹 Scheduled Task (recommended)

Run weekly, during maintenance windows.
Command:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\WSUS-AutoUpdate.ps1"
```

---

## 🗂 Logging Structure

Each operation emits a JSON message over TCP. Example:

```json
{
  "timestamp": "2025-07-20T03:00:01",
  "service": "WSUS-AutoUpdate",
  "process": "PSWindowsUpdate",
  "server": "HOST123",
  "action": "install",
  "result": "success",
  "kb": "5028185",
  "message": "Installed: 2024-07 Cumulative Update for Windows Server",
  "version": "1.6"
}
```

Actions include: `start`, `scan`, `installing`, `install`, `reboot`, `complete`, `error`.

---

## 📁 Files

| File                  | Description                              |
| --------------------- | ---------------------------------------- |
| `WSUS-AutoUpdate.ps1` | Main script                              |
| `PSWriteSyslog`       | Internal function for structured logging |

---

---

## 🧪 Example Output

```
Update script started
3 update(s) found
Installing: 2024-07 Cumulative Update
Installed: 2024-07 Cumulative Update
System reboot is required
```

---
