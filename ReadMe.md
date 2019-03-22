Minimal Ubuntu system on a VMware Horizon View infrastructure.

# Goals

- Keep it simple. The goal is not to have the absolute most minimal system. We only remove low-hanging fruit.
- Keep it layered. The base `install.sh` script has a minimal system with no tools aside from a terminal and a file manager,
  additional scripts can be built on top of it using the other scripts; see `install-polyprog.sh` for an example.

# Installation instructions

1. Download the Ubuntu 18.04 LTS "mini" ISO from https://help.ubuntu.com/community/Installation/MinimalCD
2. In vSphere Web Client, go to "VMs and Templates" > Right-click the folder you want, "New Virtual Machine" > "New Virtual Machine..."
 - Create a new virtual machine
 - Name: The name you want
 - Location: The location you want
 - Storage: The storage you want
 - Compatible with: leave unchanged
 - Guest OS Family: Linux, Guest OS Version: Ubuntu Linux (64-bit)
 - CPU : 2, Memory: 4096 MB, New Hard disk: 16 GB, Video card: 64 MB total video memory; you may need to change the network here
 - Finish
3. Still in vSphere, right-click your VM selected > "Launch console"
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
   - Copy the Horizon Client archive to /opt/horizon-client.tar.gz
   - Clone the repo, run the `install.sh` script (or a custom script, such as `install-polyprog.sh`)
