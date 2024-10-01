#!/bin/bash

# Script to harden the Mast: Ubuntu 20.04 server (with SSH enabled)

sudo -v

# Configure/Install UFW Firewall
setup_ufw() {
    echo "[*] Setting up UFW (Uncomplicated Firewall)..."
    sudo apt update
    sudo apt install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw enable
    echo "[+] UFW is installed and configured."
}

# Harden SSH configuration
harden_ssh() {
    echo "[*] Hardening SSH..."
    
    # Back up sshd_cofnig.bak
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    # Disable root login and enforce key-based authentication
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
    
    # Restart SSH to apply
    sudo systemctl restart sshd
    echo "[+] SSH has been hardened. Root login disabled, key-based authentication enforced."
}

# Configure/Install Fail2Ban
setup_fail2ban() {
    echo "[*] Installing and configuring Fail2Ban..."
    sudo apt install fail2ban -y
    
    # Create a basic Fail2Ban configuration for SSH
    cat <<EOF | sudo tee /etc/fail2ban/jail.local
    [DEFAULT]
    bantime = 3600
    findtime = 600
    maxretry = 3
    
    [sshd]
    enabled = true
    EOF
    
    # Restart Fail2Ban to apply changes
    sudo systemctl restart fail2ban
    echo "[+] Fail2Ban installed and configured to protect SSH."
}

# Disable unnecessary services (ADD MORE)
disable_unnecessary_services() {
    echo "[*] Disabling unnecessary services..."
    
    # Disable services often exploited in vulnerable machines
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    sudo systemctl stop vsftpd
    sudo systemctl disable vsftpd
    sudo systemctl stop telnet.socket
    sudo systemctl disable telnet.socket
    
    echo "[+] Unnecessary services have been disabled."
}

# Set permissions and basic file system hardening
filesystem_hardening() {
    echo "[*] Performing file system hardening..."

    # Restrict access to important system files
    sudo chmod 600 /etc/shadow
    sudo chmod 644 /etc/passwd
    sudo chmod 600 /etc/ssh/sshd_config
    sudo chown root:root /etc/ssh/sshd_config

    echo "[+] File system permissions have been hardened."
}

# Set up basic audit for monitoring key system files
setup_auditd() {
    echo "[*] Setting up auditd for file monitoring..."
    sudo apt install auditd -y

    # Add monitoring rules
    sudo auditctl -w /etc/passwd -p wa -k passwd_changes
    sudo auditctl -w /etc/shadow -p wa -k shadow_changes
    sudo auditctl -w /etc/ssh/sshd_config -p wa -k sshd_config_changes

    echo "[+] Auditd installed and monitoring critical files."
}

# Main
main() {
    echo "[*] Starting system hardening..."
    setup_ufw
    harden_ssh
    setup_fail2ban
    disable_unnecessary_services
    filesystem_hardening
    setup_auditd
    echo "[+] System hardening complete."
}

# Run the main function
main
