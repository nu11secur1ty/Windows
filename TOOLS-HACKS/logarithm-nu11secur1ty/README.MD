# 🔐 logarithm by nu11secur1ty

A PowerShell script that generates a real-time + historical **login activity report** for Windows systems in a styled HTML format.

## 📌 Features

- 🔴 **Currently Logged-In Users** (live snapshot using `quser`)
- ⚪ **Historical Logins** from Windows Security Event Log (last 7 days)
- 🌐 Generates a clean, styled **HTML report**
- 🚀 Automatically opens in your default browser

## 📁 Output

- File: `LoginReport.html`
- Location: Same directory as the script
- Contents:
  - Current sessions
  - Historical user logins
  - Timestamp of report generation

## 🚀 How to Use

### 1. **Download the Script**

Save the script as:

```
logarithm-nu11secur1ty.ps1
```

### 2. **Run in PowerShell**

> ⚠️ Must be run as **Administrator**

```powershell
.\logarithm-nu11secur1ty.ps1
```

## 📋 Requirements

- ✅ Windows (Pro/Enterprise recommended)
- ✅ PowerShell 5.1+ or PowerShell Core
- ✅ Access to Windows Security Event Logs
- ✅ `quser` available in system path

## 🔍 What It Does

### 🔴 Currently Logged-In Users

Collected with `quser`. Parsed and displayed in red.

### ⚪ Historical Logins

Collected from Event Log (`Security` → Event ID `4624`). Filters out system, service, and anonymous accounts.

## ✏️ Customize

- Change `$startTime = (Get-Date).AddDays(-7)` to go further back in history.
- Modify HTML `<style>` for custom colors.

## 🛠 Troubleshooting

| Issue | Fix |
|-------|-----|
| `quser` not found | Use Windows Pro/Enterprise or substitute with `Get-CimInstance` |
| Empty historical logins | Run as Administrator |
| HTML doesn't open | Manually open `LoginReport.html` |

## 📬 Support & Enhancements

Want more features?

- 📨 Email the report
- 📆 Schedule to run daily
- 📦 Export to `.csv`, `.pdf`, etc.
- 🛑 Detect failed logins (`Event ID 4625`)

> Contact nu11secur1ty or request an update!

## ⚖️ License

Free to use, modify, and distribute.  
Credit to **nu11secur1ty** for the name and concept.

## 👨‍💻 Author

**nu11secur1ty**  
Cybersecurity Researcher | Offensive Security  
GitHub: [nu11secur1ty](https://github.com/nu11secur1ty)
