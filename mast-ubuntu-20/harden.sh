#!/bin/bash

# Script to harden Ubuntu 20.04 server (with SSH enabled)

sudo -v

# Configure/Install UFW Firewall
setup_ufw() {
    echo "[*] Setting up UFW (Uncomplicated Firewall)..."
    sudo apt update
    sudo apt install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 3306  # Allow MySQL port for scoring access
    sudo ufw enable
    echo "[+] UFW is installed and configured."
}

# Harden SSH configuration (leaving password authentication enabled)
harden_ssh() {
    echo "[*] Hardening SSH..."
    
    # Back up sshd_config.bak
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    # Disable root login but leave password authentication enabled
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config

    # Restart SSH to apply changes
    sudo systemctl restart sshd
    echo "[+] SSH has been hardened. Root login disabled, password authentication allowed."
}

# Disable anonymous logins in MySQL
disable_mysql_anonymous() {
    echo "[*] Disabling anonymous logins in MySQL..."
    
    # Log in to MySQL and remove anonymous users
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    echo "[+] Anonymous MySQL logins have been disabled."
}

# Disable anonymous logins in vsftpd (FTP)
disable_ftp_anonymous() {
    if [ -f /etc/vsftpd.conf ]; then
        echo "[*] Disabling anonymous FTP logins..."
        
        # Disable anonymous FTP login in vsftpd config
        sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
        sudo systemctl restart vsftpd
        echo "[+] Anonymous FTP logins have been disabled."
    else
        echo "[!] vsftpd is not installed. Skipping FTP anonymous login disabling."
    fi
}

# Configure/Install Fail2Ban
setup_fail2ban() {
    echo "[*] Installing and configuring Fail2Ban..."
    sudo apt install fail2ban -y
    
    # Create a basic Fail2Ban configuration for SSH
    cat < EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 18000
findtime = 600
maxretry = 3

[sshd]
enabled = true
EOF
    
    # Restart Fail2Ban to apply changes
    sudo systemctl restart fail2ban
    echo "[+] Fail2Ban installed and configured to protect SSH."
}

# Disable unnecessary services
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

# Disable IPv6 to reduce attack surface
disable_ipv6() {
    echo "[*] Disabling IPv6..."
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo "[+] IPv6 disabled."
}

# Set up automatic security updates
setup_unattended_upgrades() {
    echo "[*] Installing unattended upgrades..."
    sudo apt install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
    echo "[+] Unattended upgrades installed and configured."
}

# Main
main() {
    echo "[*] Starting system hardening..."
    setup_ufw
    harden_ssh
    disable_mysql_anonymous
    disable_ftp_anonymous
    setup_fail2ban
    disable_unnecessary_services
    filesystem_hardening
    setup_auditd
    disable_ipv6
    setup_unattended_upgrades
    echo "[+] System hardening complete."
}

# Run the main function
main
