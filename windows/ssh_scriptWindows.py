import paramiko
import time
import logging

# SSH details
host = "198.18.0.150"  # Update this as needed
port = 22
username = "hkeating"
default_password = "Lavaswimmer2014!"
new_password = "Griffifth1997"
sudo_password = new_password  # We'll use the new password for sudo as well

# Configure logging
logging.basicConfig(level=logging.INFO)

def ssh_change_password_windows():
    try:
        # Initialize SSH client
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Equivalent to StrictHostKeyChecking=no

        # Try to connect with the default password
        logging.info(f"Attempting to SSH into {host} as {username} with default password...")
        client.connect(host, port=port, username=username, password=default_password)

        logging.info("Connected successfully!")

        # Change the password using Windows command `net user`
        change_password_command = f'net user {username} {new_password}'
        stdin, stdout, stderr = client.exec_command(change_password_command)

        logging.info("Password change command sent.")

        # Check for errors
        error = stderr.read().decode().strip()
        if error:
            logging.error(f"Error changing password: {error}")
            client.close()
            return False

        logging.info(f"Password successfully changed to {new_password}.")

        # Close the SSH connection
        client.close()
        return True

    except Exception as e:
        logging.error(f"Connection failed: {e}")
        return False


def ssh_reconnect_and_run_script_windows():
    try:
        # Initialize SSH client for the new connection
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Equivalent to StrictHostKeyChecking=no

        logging.info(f"Reconnecting to {host} with new password...")

        # Reconnect with the new password
        client.connect(host, port=port, username=username, password=new_password)

        logging.info("Reconnected successfully with new password.")

        # Download the script using PowerShell
        #logging.info("Downloading the script using PowerShell...")
        #download_script_command = f'powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/godofthunder8756/TheBandOfTheHawk/refs/heads/main/windows/configure_firewall.ps1 -OutFile C:\\Users\\{username}\\configure_firewall.ps1"'
        #stdin, stdout, stderr = client.exec_command(download_script_command)

        #error = stderr.read().decode().strip()
        #if error:
            #logging.error(f"Error downloading script: {error}")
            #client.close()
            #return False

        #logging.info("configure_firewall.ps1 script downloaded.")


        # Close the SSH connection
        client.close()
        return True

    except Exception as e:
        logging.error(f"Failed to reconnect and run the script: {e}")
        return False


def kick_off_other_users():
    try:
        # Initialize SSH client again to kick users off
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Equivalent to StrictHostKeyChecking=no

        logging.info(f"Reconnecting to {host} to log off other users...")

        # Reconnect with the new password
        client.connect(host, port=port, username=username, password=new_password)

        # Log off other users except the current session (for RDP and SSH)
        logging.info("Logging off other RDP and SSH sessions...")

        # RDP sessions logoff
        rdp_logoff_command = (
            'powershell -Command "$currentSessionId = (qwinsta | Where-Object { $_ -match $env:USERNAME } | '
            'ForEach-Object { ($_ -split \'\\s+\')[2] }).Trim(); '
            'qwinsta | Where-Object { $_ -match \'RDP\' } | ForEach-Object { '
            '$sessionId = ($_ -split \'\\s+\')[2].Trim(); if ($sessionId -ne $currentSessionId) { logoff $sessionId; '
            'Write-Host \'Logged off session: \' $sessionId } }"'
        )
        stdin, stdout, stderr = client.exec_command(rdp_logoff_command)
        logging.info(stdout.read().decode())

        # SSH sessions logoff
        ssh_logoff_command = (
            'powershell -Command "$currentSessionId = $PID; '
            '$sshSessions = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq \'sshd.exe\' -and $_.ProcessId -ne $currentSessionId }; '
            'foreach ($session in $sshSessions) { Stop-Process -Id $session.ProcessId -Force; '
            'Write-Host \'Terminated SSH session: \' $session.ProcessId }"'
        )
        stdin, stdout, stderr = client.exec_command(ssh_logoff_command)
        logging.info(stdout.read().decode())

        logging.info("Kicked off all other active users.")

        # Close the SSH connection
        client.close()

    except Exception as e:
        logging.error(f"Failed to log off other users: {e}")


def main():
    # Step 1: Change the password
    if ssh_change_password_windows():
        # Step 2: Reconnect and run the script for Windows
        if ssh_reconnect_and_run_script_windows():
            # Step 3: Kick off other users after running the firewall script
            kick_off_other_users()


if __name__ == "__main__":
    main()
