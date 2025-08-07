# 🔐 logarithm by nu11secur1ty

A PowerShell script that generates a real-time + historical **login activity report** for Windows systems in a styled HTML format.

---

## 📌 Features

- 🔴 **Currently Logged-In Users** (live snapshot using `quser`)
- ⚪ **Historical Logins** from Windows Security Event Log (last 7 days)
- 🌐 Generates a clean, styled **HTML report**
- 🚀 Automatically opens in your default browser

---

## 📁 Output

- File: `LoginReport.html`
- Location: Same directory as the script
- Contents:
  - Current sessions
  - Historical user logins
  - Timestamp of report generation

---

## 🚀 How to Use

### 1. **Download the Script**
```
logarithm-nu11secur1ty.ps1
```
---

### 2. **Run in PowerShell**

> ⚠️ Must be run as **Administrator**

```powershell
.\logarithm-nu11secur1ty.ps1

# 📋 Requirements:
- ✅ Windows (Pro/Enterprise recommended)
- ✅ PowerShell 5.1+ or PowerShell Core
- ✅ Access to Windows Security Event Logs
- ✅ quser available in system path
