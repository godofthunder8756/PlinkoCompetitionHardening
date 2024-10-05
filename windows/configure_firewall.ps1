# Define the allowed ports
$allowedPorts = "22,3389,53,80,443"

# Remove all existing inbound and outbound rules (optional, you may want to customize this part)
Write-Host "Removing all existing inbound and outbound firewall rules..." -ForegroundColor Yellow
Get-NetFirewallRule -Direction Inbound | Remove-NetFirewallRule -Confirm:$false
Get-NetFirewallRule -Direction Outbound | Remove-NetFirewallRule -Confirm:$false

# Block all inbound and outbound connections by default
Write-Host "Blocking all inbound and outbound connections by default..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Block

# Create inbound firewall rules for allowed ports
Write-Host "Creating inbound firewall rules for allowed ports..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Allow Inbound SSH (22)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22
New-NetFirewallRule -DisplayName "Allow Inbound RDP (3389)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389
New-NetFirewallRule -DisplayName "Allow Inbound DNS (53)" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 53
New-NetFirewallRule -DisplayName "Allow Inbound HTTP (80)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Allow Inbound HTTPS (443)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443

# Create outbound firewall rules for allowed ports
Write-Host "Creating outbound firewall rules for allowed ports..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Allow Outbound SSH (22)" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 22
New-NetFirewallRule -DisplayName "Allow Outbound RDP (3389)" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 3389
New-NetFirewallRule -DisplayName "Allow Outbound DNS (53)" -Direction Outbound -Action Allow -Protocol UDP -LocalPort 53
New-NetFirewallRule -DisplayName "Allow Outbound HTTP (80)" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Allow Outbound HTTPS (443)" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 443

Write-Host "Firewall rules have been successfully configured." -ForegroundColor Green
