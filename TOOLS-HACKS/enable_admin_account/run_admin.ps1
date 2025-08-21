# Enable the built-in Administrator account with user-specified password
Try {
    # Prompt for password (input is hidden)
    $SecurePass = Read-Host "Enter a password for the Administrator account" -AsSecureString

    # Convert secure string to plain text for net user command
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass)
    )

    # Enable the Administrator account
    net user Administrator /active:yes

    # Set the Administrator password
    net user Administrator $Password

    Write-Host "The Administrator account has been enabled and password set successfully." -ForegroundColor Green
}
Catch {
    Write-Host "Failed to enable the Administrator account. Run this script as Administrator." -ForegroundColor Red
}
