dd-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
# a good time to complete via remote ssh
Set-Service -Name sshd -StartupType 'Automatic'
Set-ItemProperty "HKLM:\Software\Microsoft\Powershell\1\ShellIds" -Name ConsolePrompting -Value $true
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
Write-Host "Create a deployer user: Enter Password"
$pw = Read-Host -AsSecureString
New-LocalUser -Name deployer -Password $pw -AccountNeverExpires -PasswordNeverExpires:$true
Add-LocalGroupMember -Group Administrators -Member deployer
Write-Host "Pull down unattend.xml and then sysprep the box"
wget https://raw.githubusercontent.com/gmcyber/480share/master/unattend.xml -Outfile C:\Unattend.xml
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /unattend:C:\unattend.xml
Write-Host "Set Power to High Performance"
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
