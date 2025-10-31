# GitHub Multi-Account Setup on Windows 11

> A complete guide to using multiple GitHub accounts on Windows 11, with SSH, HTTPS, and avoiding common pitfalls.

---

## Problems You Will Face on Windows 11

1. **No default `ssh_config`**
   - Windows doesn’t create an SSH config file automatically — you have to make it yourself at `C:\Users\<YourUser>\.ssh\config`

2. **SSH keys not loaded after reboot/sleep**
   - The `ssh-agent` service may not start automatically.

3. **Multiple keys confusion**
   - Plain SSH URLs (`git@github.com:owner/repo.git`) can fail if the SSH agent offers the wrong key first.

4. **HTTPS vs SSH confusion**
   - HTTPS always asks for a password/token, SSH relies on keys.

5. **Intermittent failures**
   - One account may stop working if the wrong key is first in the agent.

---

## Step 1 — Install OpenSSH Client

```powershell
# Check if OpenSSH is installed
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'

# Install if missing
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

Check version:

```powershell
ssh -V
```

---

## Step 2 — Start and Auto-Start `ssh-agent`

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

---

## Step 3 — Generate / Add Keys

```powershell
# Generate new key
ssh-keygen -t ed25519 -C "youremail@example.com" -f $env:USERPROFILE\.ssh\account1

# Add key to agent
ssh-add $env:USERPROFILE\.ssh\account1
ssh-add $env:USERPROFILE\.ssh\account2
```

Check loaded keys:

```powershell
ssh-add -l
```

---

## Step 4 — Create SSH Config File

File: `C:\Users\<YourUser>\.ssh\config`

```text
# Account 1
Host github.com-account1
    HostName github.com
    User git
    IdentityFile ~/.ssh/account1
    IdentitiesOnly yes
    AddKeysToAgent yes

# Account 2
Host github.com-account2
    HostName github.com
    User git
    IdentityFile ~/.ssh/account2
    IdentitiesOnly yes
    AddKeysToAgent yes
```

---

## Step 5 — Use SSH Alias for Git Remotes

Always use the alias in your repo:

```powershell
git remote set-url origin git@github.com-account1:account1/RepoName.git
git remote set-url origin git@github.com-account2:account2/RepoName.git
```

---

## Step 6 — Force Git to Use Windows OpenSSH

```powershell
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
```

---

## Step 7 — Test Authentication

```powershell
ssh -T git@github.com-account1
ssh -T git@github.com-account2
```

Expected output:
```
Hi account1! You've successfully authenticated, but GitHub does not provide shell access.
Hi account2! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## Step 8 — Troubleshooting

1. **403 errors on push with HTTPS**: Make sure the remote is SSH, not HTTPS.  
2. **Permission denied with SSH**: Run `ssh-add -l` to check loaded keys, confirm `.ssh/config`.  
3. **Intermittent key issues**: Use auto-load in PowerShell profile.  
4. **Cloning with SSH fails but HTTPS works**: Make sure you use the correct SSH alias in `.ssh/config`.

---

## Summary

- Windows 11 OpenSSH requires explicit aliases for multiple accounts.  
- Use `IdentitiesOnly yes` to avoid sending wrong keys.  
- Always set Git remote URLs to your SSH alias.  
- Auto-load keys in PowerShell profile to avoid intermittent failures.

***by nu11secur1ty***
