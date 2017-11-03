Install a working, minimal Ubuntu system on a vWorkspace VDI infrastructure.

# Installation instructions

1. Download the Ubuntu 16.04 LTS "mini" ISO from https://help.ubuntu.com/community/Installation/MinimalCD
2. In vSphere Web Client, go to "VMs and Templates" > Right-click the folder you want, New Virtual Machine > New Virtual Machine...
 - Create a new virtual machine
 - Name: The name you want
 - Location: The location you want
 - Storage: The storeage you want
 - Compatible with: leave unchanged - ESXi 6.0 and later
 - Guest OS Family: Linux, Guest OS Version: Ubuntu Linux (64-bit)
 - CPU : 2, Memory: 4096 MB, New Hard disk: 32 GB, you may need to change the network here
 - Finish
3. Still in vSphere, with your VM selected, click on "Launch remote console"
4. In the remote console:
 - VMRC > Manage > Virtual Machine Settings > click on CD/DVD drive 1
   - Check "Connect at power on"
   - Select "Use ISO image file", pick the ISO downloaded in step 1
   - OK
 - Power on the VM. The Ubuntu installer now launches.
   - Command line install
   - Pick your language
   - Pick your location
   - Pick your locale
   - Pick your keyboard layout
   - Network autoconfiguration should succeed
   - Pick a hostname
   - Pick your archive mirror country and mirror
   - No proxy
   - User: live
   - Username: live
   - Password: live
   - Confirm password: live
   - Encrypt home directory: No
   - Confirm time zone: Yes (assuming it's correct)
   - Partitioning method: Guided - use entire disk
   - Partition the only disk choice
   - Write the changes to disks: yes
   - No automatic updates
   - Install GRUB to master boot record: Yes
   - System clock to UTC: Yes
   - In the remote console, VMRC > Manage > Virtual Machine Settings > click on CD/DVD drive 1
     - Uncheck both "Connected" and "Connect at power on"
   - In the setup, Continue
   - At the password prompt, login as live
   - `sudo passwd root`, give a new password
   - exit
   - Login as root
   - `userdel -rf live`
   - `apt install -y --no-install-recommends openssh-server git`
   - You may want to edit /etc/ssh/sshd_config to set PermitRootLogin to `yes` rather than `prohibit-password`, for convenience, then `systemctl restart sshd`
   - Put the VDEFORLINUX folder from the vWorkspace tools in /opt
   - Clone the repo, run the `install.sh` script (or a custom script, such as `install-hc2.sh`)
