#!/bin/sh
# Minor fixes to avoid spurious errors

# i2c_piix4 is a module that deals with the PIIX4 chip's System Management Bus (SMBus), but VMWare doesn't support it
# Not a huge deal, it just prints an error line on boot, but that's not very nice, we want no errors
echo '# Disabled since VMWare does not support it' >> '/etc/modprobe.d/blacklist.conf'
echo 'blacklist i2c_piix4' >> '/etc/modprobe.d/blacklist.conf'

# Remove KWallet and GNOME Keyring integration that LightDM adds to PAM (we don't have either, they cause errors)
sed -i '/kwallet\|gnome_keyring/d' '/etc/pam.d/lightdm'
