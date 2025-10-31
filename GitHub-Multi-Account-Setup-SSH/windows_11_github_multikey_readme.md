# GitHub Multi-Account Setup on Windows 11

This guide is tailored to using **two GitHub accounts** on Windows 11 with SSH, covering common issues, fixes, and best practices.

---

## 1. Problems on Windows 11

- Windows 11 has **no default `ssh_config`**; you need to create it.
- `ssh-agent` may not start automatically.
- Multiple keys can cause SSH to pick the wrong one.
- Using HTTPS instead of SSH can cause 403 errors or credential prompts.
- Keys may intermittently fail if the wrong one is first in the agent.

---

## 2. Install OpenSSH Client

```powershell
# Check installed capabilities
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'

# Install if missing
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

Check version:
```powershell
ssh -V
```

---

## 3. Start ssh-agent

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

---

## 4. Generate / Add SSH Keys

```powershell
ssh-keygen -t ed25519 -C "email1@example.com" -f $env:USERPROFILE\.ssh\account1
ssh-keygen -t ed25519 -C "email2@example.com" -f $env:USERPROFILE\.ssh\account2

ssh-add $env:USERPROFILE\.ssh\account1
ssh-add $env:USERPROFILE\.ssh\account2
ssh-add -l  # Verify loaded keys
```

---

## 5. Create SSH Config File

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

## 6. Set Git Remote URLs Using Aliases

```powershell
git remote set-url origin git@github.com-account1:account1/RepoName.git
# or
git remote set-url origin git@github.com-account2:account2/RepoName.git
```

Always use your **SSH alias**, not the plain `git@github.com:...` URL.

---

## 7. Test SSH Authentication

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

## 8. Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Permission denied (publickey)` | Wrong key offered | Check `ssh-add -l` and `.ssh/config` aliases |
| `remote: Permission denied to user` | Wrong account pushing | Change remote to correct SSH alias |
| HTTPS asking for password | Using HTTPS URL | Switch remote to SSH or use Personal Access Token |

---

## 9. Optional: Git Commands for Clean Setup

```powershell
# Remove old keys from agent
ssh-add -D

# Remove old remotes
git remote remove origin
```

---

## 10. Summary

- Use `.ssh/config` with **aliases** for multiple GitHub accounts.  
- Use `IdentitiesOnly yes` to force SSH to select the correct key.  
- Always set Git remote URLs to your SSH alias.  
- Auto-load keys via `ssh-agent` to avoid intermittent failures.  
- HTTPS can work but requires PATs and is less flexible for multiple accounts.

---

This setup ensures both accounts work independently without conflicts on Windows 11.

