import paramiko
import time
import logging

# SSH details
host = "172.16.3.30"  # Update this as needed
port = 22
username = "plinktern"
default_password = "HPCCrulez!"
new_password = "Griffifth1997"
sudo_password = new_password  # We'll use the new password for sudo as well

# Configure logging
logging.basicConfig(level=logging.INFO)

def ssh_change_password():
    while True:
        try:
            # Initialize SSH client
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Equivalent to StrictHostKeyChecking=no

            # Try to connect with the default password
            logging.info(f"Attempting to SSH into {host} as {username} with default password...")
            client.connect(host, port=port, username=username, password=default_password)

            logging.info("Connected successfully!")

            # Change the password command
            stdin, stdout, stderr = client.exec_command(f'echo -e "{default_password}\\n{new_password}\\n{new_password}" | passwd')

            logging.info("Password change command sent.")

            # Check for errors
            error = stderr.read().decode().strip()
            if "passwd:" not in error:
                logging.error(f"Error changing password: {error}")
                client.close()
                continue

            logging.info(f"Password successfully changed to {new_password}.")

            # Kick off all users except the current session
            stdin, stdout, stderr = client.exec_command("who | grep -v $(whoami) | awk '{print $1}' | xargs -r pkill -KILL -u")

            logging.info("Kicked off all other active users.")

            # Close the SSH connection
            client.close()
            break  # Exit the loop once successful

        except Exception as e:
            logging.error(f"Connection failed: {e}. Retrying in 5 seconds...")
            time.sleep(5)  # Wait before retrying

def ssh_reconnect_and_run_script():
    try:
        # Initialize SSH client for the new connection
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # Equivalent to StrictHostKeyChecking=no

        logging.info(f"Reconnecting to {host} with new password...")

        # Reconnect with the new password
        client.connect(host, port=port, username=username, password=new_password)

        logging.info("Reconnected successfully with new password.")

        # Download the harden.sh script using curl
        logging.info("Downloading harden.sh script...")
        stdin, stdout, stderr = client.exec_command('curl -O https://raw.githubusercontent.com/godofthunder8756/TheBandOfTheHawk/refs/heads/main/mast-ubuntu-20/harden.sh')

        error = stderr.read().decode().strip()
        if error:
            logging.error(f"Error downloading script: {error}")
            client.close()
            return

        logging.info("harden.sh script downloaded.")

        # Run the harden.sh script with sudo
        logging.info("Running the harden.sh script with sudo...")
        stdin, stdout, stderr = client.exec_command(f"echo {sudo_password} | sudo -S bash harden.sh")

        stdout = stdout.read().decode()
        error = stderr.read().decode().strip()
        if error:
            logging.error(f"Error running script: {error}")
        else:
            logging.info(f"Script output: {stdout}")

        logging.info("harden.sh script executed successfully.")

        # Close the SSH connection
        client.close()

    except Exception as e:
        logging.error(f"Failed to reconnect and run the script: {e}")

def main():
    # Step 1: Change the password and kick off users
    ssh_change_password()

    # Step 2: Reconnect and run the harden.sh script
    ssh_reconnect_and_run_script()

if __name__ == "__main__":
    main()