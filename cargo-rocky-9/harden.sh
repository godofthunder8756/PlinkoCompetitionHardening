#!/bin/bash

# Script to harden Rocky Linux 9 server (with SSH and FTP enabled)

sudo -v

# Configure/Install firewalld Firewall
setup_firewalld() {
    echo "[*] Setting up firewalld..."
    sudo dnf install firewalld -y
    sudo systemctl enable firewalld --now
    
    # Set default policies
    sudo firewall-cmd --set-default-zone=public
    sudo firewall-cmd --permanent --zone=public --add-service=ssh
    sudo firewall-cmd --permanent --zone=public --add-service=ftp
    sudo firewall-cmd --reload
    
    echo "[+] firewalld is installed and configured. SSH and FTP allowed."
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

# Disable MySQL if it is running
disable_mysql() {
    echo "[*] Disabling MySQL service..."
    sudo systemctl stop mysqld
    sudo systemctl disable mysqld
    echo "[+] MySQL service has been disabled."
}

# Ensure FTP is enabled with vsftpd and anonymous logins are disabled
setup_vsftpd() {
    echo "[*] Configuring vsftpd for FTP services..."
    sudo dnf install vsftpd -y
    sudo systemctl enable vsftpd --now
    
    # Disable anonymous FTP login
    sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
    sudo systemctl restart vsftpd
    echo "[+] vsftpd installed and configured. Anonymous logins disabled."
}

# Configure/Install Fail2Ban
setup_fail2ban() {
    echo "[*] Installing and configuring Fail2Ban..."
    sudo dnf install epel-release -y
    sudo dnf install fail2ban -y
    
    # Create a basic Fail2Ban configuration for SSH
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 18000
findtime = 600
maxretry = 3

[sshd]
enabled = true

[vsftpd]
enabled = true
EOF
    
    # Restart Fail2Ban to apply changes
    sudo systemctl enable fail2ban --now
    sudo systemctl restart fail2ban
    echo "[+] Fail2Ban installed and configured to protect SSH and FTP."
}

# Disable unnecessary services
disable_unnecessary_services() {
    echo "[*] Disabling unnecessary services..."
    
    # Disable services that are not needed for SSH and FTP
    sudo systemctl stop httpd
    sudo systemctl disable httpd
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
    sudo dnf install audit -y

    # Add monitoring rules
    sudo auditctl -w /etc/passwd -p wa -k passwd_changes
    sudo auditctl -w /etc/shadow -p wa -k shadow_changes
    sudo auditctl -w /etc/ssh/sshd_config -p wa -k sshd_config_changes
    sudo auditctl -w /etc/vsftpd/vsftpd.conf -p wa -k vsftpd_config_changes

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
    echo "[*] Installing and configuring automatic security updates..."
    sudo dnf install dnf-automatic -y
    sudo systemctl enable --now dnf-automatic.timer
    echo "[+] Automatic security updates configured."
}

# Main
main() {
    echo "[*] Starting system hardening..."
    setup_firewalld
    harden_ssh
    disable_mysql
    setup_vsftpd
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
