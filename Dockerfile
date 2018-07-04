FROM ubuntu:16.04
MAINTAINER Jacob <chenjr0719@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV USER ubuntu
ENV HOME /home/$USER

# Create new user for vnc login.
RUN adduser $USER --disabled-password

# Install Ubuntu Unity.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ubuntu-desktop \
        unity-lens-applications \
        gnome-panel \
        metacity \
        nautilus \
        gedit \
        xterm \
        sudo

# Install dependency components.
RUN apt-get install -y \
        supervisor \
        net-tools \
        curl \
        git \
        pwgen \
        libtasn1-3-bin \
        libglu1-mesa \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Copy tigerVNC binaries
ADD tigervnc-1.8.0.x86_64 /

# Clone noVNC.
RUN git clone https://github.com/novnc/noVNC.git $HOME/noVNC

# Clone websockify for noVNC
Run git clone https://github.com/kanaka/websockify $HOME/noVNC/utils/websockify

# # Download ngrok.
# ADD https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip $HOME/ngrok/ngrok.zip
# RUN unzip -o $HOME/ngrok/ngrok.zip -d $HOME/ngrok && rm $HOME/ngrok/ngrok.zip

# Copy supervisor config
COPY supervisor.conf /etc/supervisor/conf.d/

# Set xsession of Unity
COPY xsession $HOME/.xsession


#################################################################################################################
#   INITIALIZE R
#################################################################################################################

# ARG R_BASE_VER=3.4.4
# ARG R_BASE_VER=3.5.0
ARG R_BASE_VER=3.5.1

# add to sources lists Michael Rutter's Launchpad repo with R-base 3.5 (RRutter v3.5)
RUN echo "deb [trusted=yes] http://ppa.launchpad.net/marutter/rrutter3.5/ubuntu xenial main" > /etc/apt/sources.list.d/rrutter3.5_xenial.list
# RUN echo "deb [trusted=yes] http://ppa.launchpad.net/marutter/rrutter3.5/ubuntu bionic main" > /etc/apt/sources.list.d/rrutter3.5_bionic.list

# add Michael Rutters key
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# Now install R-base[-dev] 3.5.0 from Michael Rutter's Launchpad repo
RUN apt-get update && apt-get install -y \
		r-base=${R_BASE_VER}-* \
		r-base-dev=${R_BASE_VER}-* \
		r-recommended=${R_BASE_VER}-*


### NoMachine ###

# Goto https://www.nomachine.com/download/download&id=10 and update the latest 
# NOMACHINE_PACKAGE_NAME and MD5 sum:
# ENV NOMACHINE_PACKAGE_NAME nomachine_5.3.12_10_amd64.deb
# ENV NOMACHINE_MD5 78f25ceb145b1e6972bb6ad2c69bf689
# ENV NOMACHINE_PACKAGE_NAME nomachine_6.0.78_1_amd64.deb
# ENV NOMACHINE_BUILD 6.0
# ENV NOMACHINE_MD5 3645673090788ea0b2a3f664bb71a7dd
ENV NOMACHINE_PACKAGE_NAME nomachine_6.2.4_1_amd64.deb
ENV NOMACHINE_BUILD 6.2
ENV NOMACHINE_MD5 210bc249ec9940721a1413392eee06fe

# Install nomachine, change password and username to whatever you want here
RUN curl -fSL "http://download.nomachine.com/download/${NOMACHINE_BUILD}/Linux/${NOMACHINE_PACKAGE_NAME}" -o nomachine.deb \
&& echo "${NOMACHINE_MD5} *nomachine.deb" | md5sum -c - && dpkg -i nomachine.deb

# edit the Nomachine node configuration;
# caution: both node.cfg and server.cfg files 
# must be edited for the changes to take effect;
# define the location and names of the config files
ARG NX_NODE_CFG=/usr/NX/etc/node.cfg
ARG NX_SRV_CFG=/usr/NX/etc/server.cfg
# (note we edit the config files *[i]n place* (hence sed -i)
# and replace *[c]omplete* lines using "c\" switch):
# - replace the default desktop command (DefaultDesktopCommand) used by NoMachine with the preferred (lightweight) desktop
# LXDE
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/lxde"' $NX_NODE_CFG
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/lxde"' $NX_SRV_CFG
# KDE
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startkde"' $NX_NODE_CFG
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startkde"' $NX_SRV_CFG
# Cinnamon
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/cinnamon"' $NX_NODE_CFG
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/cinnamon"' $NX_SRV_CFG
# Unity
# DefaultDesktopCommand "/etc/X11/Xsession 'gnome-session --session=ubuntu'"
# CommandStartGnome "/etc/X11/Xsession 'gnome-session --session=ubuntu'"
RUN sed -i "/DefaultDesktopCommand/c\DefaultDesktopCommand \"/etc/X11/Xsession 'gnome-session --session=ubuntu'\" " $NX_NODE_CFG
RUN sed -i "/DefaultDesktopCommand/c\DefaultDesktopCommand \"/etc/X11/Xsession 'gnome-session --session=ubuntu'\" " $NX_SRV_CFG
# # Gnome
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "env GNOME_SHELL_SESSION_MODE=classic gnome-session --session gnome-classic" ' $NX_NODE_CFG
# RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "env GNOME_SHELL_SESSION_MODE=classic gnome-session --session gnome-classic" ' $NX_SRV_CFG
# # set default desktop using docker's environmental variable
# ENV GNOME_SHELL_SESSION_MODE="classic gnome-session --session gnome-classic"

# # - replace the location of the nxserver log file, because the default one required sudo 
# # (but first create a new folder and empty logfile inside the user home folder)
# COPY nxserver.log /tmp
# RUN chown $NX_USER:$NX_GID /tmp/nxserver.log
# RUN sed -i "/SystemLogFile/c\SystemLogFile ${LOG_FOLDER}nxserver.log" $NX_NODE_CFG && \
# 	sed -i "/SystemLogFile/c\SystemLogFile ${LOG_FOLDER}nxserver.log" $NX_SRV_CFG

# # instead of blind editing using sed, simply edit the config files
# # outside the container (in git), and then copy them to the container
# COPY node.cfg /usr/NX/etc/node.cfg
# COPY server.cfg /usr/NX/etc/server.cfg

# add nx_user to sudoers file but only for startup of the nxserver service
RUN echo "${NX_USER} ALL=(ALL:ALL) NOPASSWD: /etc/NX/nxserver --startup" >> /etc/sudoers && \
	# add also nx_user to sudoers file but only for nxserver log monitoring
	echo "${NX_USER} ALL=(ALL:ALL) NOPASSWD: /usr/bin/tail -f /usr/NX/var/log/nxserver.log" >> /etc/sudoers


# Copy startup script
COPY startup.sh $HOME

EXPOSE 4000
EXPOSE 6080 5901 4040 
CMD ["/bin/bash", "/home/ubuntu/startup.sh"]
