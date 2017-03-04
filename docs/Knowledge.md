This file contains information learned while creating this repository.  
It exists as documentation for those who wish to modify the scripts.

### Services

The virtual machines must run three services to be usable:

- `open-vm-tools`, the VMware tools; can be installed via `apt`, no configuration needed.
- `qdcsvc`, the *Q*uest *D*ata *C*ollector *S*er*v*i*c*e; comes in the `VDEFORLINUX` folder of the vWorkspace tools,
  must be manually installed, and depends on `libwinpr` (an emulation layer for Windows APIs on Linux, part of FreeRDP)
  and `libfreerds-{rdsapi, rpc}`, two libraries from FreeRDS.  
  Unfortunately the packages containing `libwinpr` are from a newer version in which it is split into chunks,
  thus the safest way to get `qdcsvc` to work is to compile FreeRDS and add the resulting libs to `/lìb`.
- An RDP server, either FreeRDS or XRDP. FreeRDS is an old, experimental, unstable, unmaintained project.
  XRDP is still maintained.

### Scripts

The vWorkspace tools come with two important scripts:

- `qdcip.all` needs to run on boot; it communicates with the outside world by reading from the floppy disk.
  If it finds an `unattend.xml` file (normally used by Windows), it parses it and configures the machine
  to use LDAP, by creating Samba, Kerberos and NTP config files. Then it deletes the file.
- `vwts.all` is the installation script, designed to install either FreeRDS or XRDP, as well as set up the rest.
  However, it uses old ways of doing things such as init.d scripts instead of systemd, and by default will
  attempt to clone an old version of XRDP. If it finds the XRDP source, it will use it instead of cloning;
  changing the constants at the start of the script is necessary to do so.

Note that by default, the scripts log everything to disk, which includes passwords.
