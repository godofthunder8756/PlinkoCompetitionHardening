import paramiko
import time
import logging

# SSH details
host = "198.18.3.142"  # Update this as needed
port = 22
username = "plinktern"
default_password = "HPCCrulez!"
new_password = "Griffifth1997"
sudo_password = new_password  # We'll use the new password for sudo as well

# Configure logging
logging.basicConfig(level=logging.INFO)

def ssh_change_password_windows():
    while True:
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
                continue

            logging.info(f"Password successfully changed to {new_password}.")

            # Kick off all users except the current session (Windows equivalent of kicking users)
            # RDP
            stdin, stdout, stderr = client.exec_command(
    'powershell -Command "$currentSessionId = (qwinsta | Where-Object { $_ -match $env:USERNAME } | ForEach-Object { ($_ -split \'\\s+\')[2] }).Trim(); '
    'qwinsta | Where-Object { $_ -match \'RDP\' } | ForEach-Object { $sessionId = ($_ -split \'\\s+\')[2].Trim(); '
    'if ($sessionId -ne $currentSessionId) { logoff $sessionId; Write-Host \'Logged off session: \' $sessionId } }"'
)           # SSH
            stdin, stdout, stderr = client.exec_command(
    'powershell -Command "$currentSessionId = $PID; '
    '$sshSessions = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq \'sshd.exe\' -and $_.ProcessId -ne $currentSessionId }; '
    'foreach ($session in $sshSessions) { '
    'Stop-Process -Id $session.ProcessId -Force; Write-Host \'Terminated SSH session: \' $session.ProcessId }"'
)



            logging.info("Kicked off all other active users.")

            # Close the SSH connection
            client.close()
            break  # Exit the loop once successful

        except Exception as e:
            logging.error(f"Connection failed: {e}. Retrying in 5 seconds...")
            time.sleep(5)  # Wait before retrying

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
        logging.info("Downloading the script using PowerShell...")
        download_script_command = f'powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/godofthunder8756/TheBandOfTheHawk/refs/heads/main/cargo-rocky-9/harden.sh -OutFile C:\\Users\\{username}\\hardener.ps1"'
        stdin, stdout, stderr = client.exec_command(download_script_command)

        error = stderr.read().decode().strip()
        if error:
            logging.error(f"Error downloading script: {error}")
            client.close()
            return

        logging.info("harden.ps1 script downloaded.")

        # Run the script using PowerShell
        #logging.info("Running the script with PowerShell...")
        #run_script_command = f'powershell -ExecutionPolicy Bypass -File C:\\Users\\{username}\\harden.ps1'
        #stdin, stdout, stderr = client.exec_command(f"echo {sudo_password} | {run_script_command}")

        #stdout_data = stdout.read().decode()
        #error = stderr.read().decode().strip()
        #if error:
        #    logging.error(f"Error running script: {error}")
        #else:
        #    logging.info(f"Script output: {stdout_data}")

        #logging.info("harden.ps1 script executed successfully.")

        # Close the SSH connection
        client.close()

    except Exception as e:
        logging.error(f"Failed to reconnect and run the script: {e}")

def main():
    # Step 1: Change the password and kick off users
    ssh_change_password_windows()

    # Step 2: Reconnect and run the script for Windows
    ssh_reconnect_and_run_script_windows()

if __name__ == "__main__":
    main()
