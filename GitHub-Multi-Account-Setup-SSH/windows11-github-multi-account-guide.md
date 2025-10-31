
# Windows 11 — GitHub Multi‑Account SSH Guide (Public-friendly)

A complete, example-driven guide to using multiple GitHub accounts on Windows 11.  
This file is written for *other people* — it contains generic examples, full commands, clear explanations, and troubleshooting steps. **No personal data included.**

---
## Overview

Windows users often run into problems when they want to use **more than one GitHub account** from the same machine. The issues usually come from:
- multiple SSH keys loaded into the agent,
- Git using HTTPS and cached credentials,
- the SSH client offering the "wrong" key first,
- or differences between Git-for-Windows' `ssh` and Windows OpenSSH.

This guide shows a clean, reproducible method using **SSH host aliases** in `~/.ssh/config` so each repo uses the correct key every time.

---
## 1. Generate SSH keys (examples)

Open PowerShell and run (replace email/address placeholders):

```powershell
# account A
ssh-keygen -t ed25519 -C "accountA@example.com" -f $env:USERPROFILE\.ssh\accountA_key

# account B
ssh-keygen -t ed25519 -C "accountB@example.com" -f $env:USERPROFILE\.ssh\accountB_key
```

This produces files like:
```
C:\Users\<you>\.ssh\accountA_key           (private)
C:\Users\<you>\.ssh\accountA_key.pub       (public)
```

---
## 2. Start ssh-agent and add keys

```powershell
# start the agent and make it persistent (run once as Administrator if desired)
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# add keys to the agent
ssh-add $env:USERPROFILE\.ssh\accountA_key
ssh-add $env:USERPROFILE\.ssh\accountB_key

# list loaded keys
ssh-add -l
```

If the agent has no identities, add them as shown above.

---
## 3. Add public keys to GitHub accounts

For each account, copy the public key and add it to GitHub:

```powershell
Get-Content $env:USERPROFILE\.ssh\accountA_key.pub | Set-Clipboard
# then go to GitHub -> Settings -> SSH and GPG keys -> New SSH key -> paste
```

Make sure you add the correct public key to the corresponding GitHub account.

---
## 4. Create SSH host aliases (the secret sauce)

Create or edit `C:\Users\<you>\.ssh\config` and add host aliases. **Do not include actual private keys — only paths.**

Example `~/.ssh/config` (generic):

```
# GitHub - account A
Host github-accountA
    HostName github.com
    User git
    IdentityFile C:/Users/<you>/.ssh/accountA_key
    IdentitiesOnly yes
    AddKeysToAgent yes

# GitHub - account B
Host github-accountB
    HostName github.com
    User git
    IdentityFile C:/Users/<you>/.ssh/accountB_key
    IdentitiesOnly yes
    AddKeysToAgent yes
```

Notes:
- Use full Windows paths with forward slashes or `~/.ssh/...` depending on your environment.
- `IdentitiesOnly yes` is important: it prevents the agent from trying every key and ensures only the configured `IdentityFile` is used for that alias.
- `AddKeysToAgent yes` will attempt to add the key to the agent when first used (supported by recent OpenSSH versions).

---
## 5. Clone or change remotes using the alias

**Clone using the alias** (recommended):

```powershell
git clone git@github-accountA:accountA/repo.git
git clone git@github-accountB:accountB/another-repo.git
```

**Convert existing repo's remote** (from HTTPS to aliased SSH):

```powershell
cd path\to\repo
git remote set-url origin git@github-accountA:accountA/repo.git
git remote -v
```

Check `git remote -v` always — `git@...` is SSH; `https://...` is HTTPS.

---
## 6. Forcing a single key for one-off commands

If you need to temporarily force a specific key without changing remotes, use `GIT_SSH_COMMAND` (PowerShell):

```powershell
$env:GIT_SSH_COMMAND = "ssh -i $env:USERPROFILE\.ssh\accountA_key -o IdentitiesOnly=yes"
git clone git@github.com:accountA/repo.git
Remove-Item Env:GIT_SSH_COMMAND
```

This forces the SSH command used for that git invocation only.

---
## 7. Make Git use Windows OpenSSH consistently (optional)

If you have multiple `ssh` binaries (Git-for-Windows and Windows OpenSSH), pick one for consistency:

```powershell
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
```

---
## 8. Common problems & fixes

### Problem: `Permission denied (publickey)` when cloning or pushing
- SSH offered the wrong key or no key was offered.
- Fixes:
  - Ensure public key is added to target GitHub account.
  - Use the alias clone URL (see step 5) so the right key is used.
  - Add the key to agent: `ssh-add C:\Users\<you>\.ssh\accountA_key`
  - Test explicit key: `ssh -T git@github.com -i C:\Users\<you>\.ssh\accountA_key -o IdentitiesOnly=yes`

### Problem: `remote: Permission to owner/repo denied to user`
- You're authenticated as a different GitHub account (likely via HTTPS cached credentials).
- Fixes:
  - Convert the repo remote to the SSH alias for the correct account.
  - Or remove cached Windows credentials: Control Panel → Credential Manager → Windows Credentials → remove GitHub entries.

### Problem: Keys work in terminal but fail in IDE / GUI apps
- Some apps ship their own bundled SSH or Git. Make sure they use the same `ssh` and `ssh-agent` as your terminal or configure them explicitly.

---
## 9. Debugging tips (verbose output)

Useful commands when things fail; paste the relevant parts into help requests.

- See which keys agent has:
```powershell
ssh-add -l
```

- Verbose test of a specific key:
```powershell
ssh -T git@github.com -i $env:USERPROFILE\.ssh\accountA_key -o IdentitiesOnly=yes -vvv
```

- Force the SSH client to print verbose debug when git runs:
```powershell
$env:GIT_SSH_COMMAND = 'ssh -vvv'
git clone git@github.com:accountA/repo.git 2>&1 | Out-String -Width 4096
Remove-Item Env:GIT_SSH_COMMAND
```

Look for these lines in verbose output:
- `Offering public key: ...` — which key is proposed
- `Server accepts key: ...` — key accepted
- `Authenticated to github.com ... using "publickey"` — success
- `Authentications that can continue: publickey` — key rejected

---
## 10. Why HTTPS can appear to "just work" on Windows

Windows ships Git Credential Manager which caches (or refreshes) credentials and may use browser-based OAuth flows. That can make HTTPS pushes succeed without prompting, and it can appear to “magically” authenticate for you. This is **not** using your SSH keys — it's HTTPS credentials or tokens. The behavior can be inconsistent when you also use SSH keys, so for multi-account setups SSH with aliases is the recommended predictable approach.

---
## 11. Example debug snippet (public-friendly)

This shows the important parts of a successful SSH handshake (cleaned from any personal info):

```
debug1: Offering public key: C:/Users/<you>/.ssh/accountA_key RSA SHA256:... explicit agent
debug1: Server accepts key: C:/Users/<you>/.ssh/accountA_key RSA SHA256:... explicit agent
Authenticated to github.com using "publickey".
Hi accountA! You've successfully authenticated, but GitHub does not provide shell access.
```

---
## 12. Appendix: Helpful quick commands

- Start agent and add keys:
```powershell
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\accountA_key
ssh-add $env:USERPROFILE\.ssh\accountB_key
ssh-add -l
```

- Convert existing remote to SSH alias:
```powershell
git remote set-url origin git@github-accountA:accountA/repo.git
```

- Remove cached Windows GitHub credentials:
  - Control Panel → Credential Manager → Windows Credentials → remove entries for `github.com`

---
## License & Attribution

This document is public domain / CC0-like: copy, paste, modify, and share it. It is intentionally generic and contains example placeholders — replace `accountA`, `accountB`, and file names with your own values when following it.

***by nu11secur1ty***
