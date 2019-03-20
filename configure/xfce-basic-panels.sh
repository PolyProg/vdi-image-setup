#!/bin/sh
# Sets the default XFCE desktop configuration (so new users don't get prompts)

mkdir -p /etc/skel/.config/menus
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

# Applications menu
cat > '/etc/skel/.config/menus/xfce-applications.menu' << 'EOF'
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
    <Name>Xfce</Name>

    <DefaultAppDirs/>
    <DefaultDirectoryDirs/>
    <DefaultMergeDirs/>

    <Include>
        <Category>X-Xfce-Toplevel</Category>
    </Include>
    <Exclude>
        <Filename>exo-mail-reader.desktop</Filename>
    </Exclude>

    <Layout>
        <Filename>exo-terminal-emulator.desktop</Filename>
        <Filename>exo-file-manager.desktop</Filename>
        <Filename>exo-web-browser.desktop</Filename>
        <Separator/>
        <Merge type="all"/>
        <Separator/>
        <Filename>xfce4-session-logout.desktop</Filename>
    </Layout>

    <Menu>
        <Name>Accessories</Name>
        <Directory>xfce-accessories.directory</Directory>
        <Include>
            <Or>
                <Category>Accessibility</Category>
                <Category>Core</Category>
                <Category>Legacy</Category>
                <Category>Utility</Category>
            </Or>
        </Include>
    </Menu>

    <Menu>
        <Name>Development</Name>
        <Directory>xfce-development.directory</Directory>
        <Include>
            <Category>Development</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Education</Name>
        <Directory>xfce-education.directory</Directory>
        <Include>
            <Category>Education</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Games</Name>
        <Directory>xfce-games.directory</Directory>
        <Include>
            <Category>Game</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Graphics</Name>
        <Directory>xfce-graphics.directory</Directory>
        <Include>
            <Category>Graphics</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Multimedia</Name>
        <Directory>xfce-multimedia.directory</Directory>
        <Include>
            <Category>Audio</Category>
            <Category>Video</Category>
            <Category>AudioVideo</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Network</Name>
        <Directory>xfce-network.directory</Directory>
        <Include>
            <Category>Network</Category>
        </Include>
        <Exclude>
            <Or>
                <Filename>exo-mail-reader.desktop</Filename>
                <Filename>exo-web-browser.desktop</Filename>
            </Or>
        </Exclude>
    </Menu>

    <Menu>
        <Name>Office</Name>
        <Directory>xfce-office.directory</Directory>
        <Include>
            <Category>Office</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>Settings</Name>
        <Directory>xfce-settings.directory</Directory>
        <Include>
            <Category>Settings</Category>
        </Include>
    </Menu>

    <Menu>
        <Name>System</Name>
        <Directory>xfce-system.directory</Directory>
        <Include>
            <Or>
                <Category>Emulator</Category>
                <Category>System</Category>
            </Or>
        </Include>
    </Menu>

    <Menu>
        <Name>Other</Name>
        <Directory>xfce-other.directory</Directory>
        <OnlyUnallocated/>
        <Include>
            <All/>
        </Include>
    </Menu>
</Menu>
EOF

# Desktop
cat > '/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorrdp0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-teal.jpg"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-removable" type="bool" value="false"/>
      <property name="show-trash" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-home" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF

# Panels (e.g. task bar)
cat > '/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="3"/>
        <value type="int" value="15"/>
        <value type="int" value="5"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-15" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-5" type="string" value="clock"/>
  </property>
</channel>
EOF

# Other settings
# We set this just to disable workspaces so people don't get confused by accidentally switching between workspaces
cat > '/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml' << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="workspace_count" type="int" value="1"/>
  </property>
</channel>
EOF

# Also set the panels for root
mkdir -p /root/.config/
cp -r /etc/skel/.config/. /root/.config/
