# FOR APPLE SILICON (I.E. M1 MACBOOK) !!
# FOR APPLE SILICON (I.E. M1 MACBOOK) !!
# FOR APPLE SILICON (I.E. M1 MACBOOK) !!
# ============================================= #
# ========    ROS & GAZEBO  with RDP   ======== #
# ============================================= #
# --------      Versions      -------- #
# Ubuntu : 24.04
# ROS : Jazzy
# Gazebo : Harmonic
# ------------------------------------ #
# To Build
# docker build -t jazzy-harmonic-rdp -f jazzy-harmonic-rdp.dockerfile .
# To Run
# docker run -it -p 3389:3389 -p 22:22 jazzy-harmonic-rdp
# To connect
# connect using RDP at localhost:3389 with USER/PASS (efault: ioes/ioes)

# Starting from ubuntu 24.04 with RDP support
FROM arm64v8/ubuntu:24.04
EXPOSE 3389/tcp
# EXPOSE 22/tcp
ARG USER=ioes
ARG PASS=ioes
ARG X11Forwarding=false

# Set RDP and SSH environments
# access with any RDP client at localhost:3389 with USER/PASS)
# SSh connect and forward X11 with USER/PASS at localhost:22

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
        apt-get install -y ubuntu-desktop-minimal dbus-x11 xrdp sudo; \
    [ $X11Forwarding = 'true' ] && apt-get install -y openssh-server; \
    apt-get autoremove --purge; \
    apt-get clean; \
    rm /run/reboot-required*

RUN useradd -s /bin/bash -m $USER -p $(openssl passwd "$PASS"); \
    usermod -aG sudo $USER; \
    adduser xrdp ssl-cert; \
    # Setting the required environment variables
    echo 'LANG=en_US.UTF-8' >> /etc/default/locale; \
    echo 'export GNOME_SHELL_SESSION_MODE=ubuntu' > /home/$USER/.xsessionrc; \
    echo 'export XDG_CURRENT_DESKTOP=ubuntu:GNOME' >> /home/$USER/.xsessionrc; \
    echo 'export XDG_SESSION_TYPE=x11' >> /home/$USER/.xsessionrc; \
    # Enabling log to the stdout
    sed -i "s/#EnableConsole=false/EnableConsole=true/g" /etc/xrdp/xrdp.ini; \
    # Disabling system animations and reducing the
    # image quality to improve the performance
    sed -i 's/max_bpp=32/max_bpp=16/g' /etc/xrdp/xrdp.ini; \
    gsettings set org.gnome.desktop.interface enable-animations true; \
    # Listening on wildcard address for X forwarding
    [ $X11Forwarding = 'true' ] && \
        sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/g' /etc/ssh/sshd_config || \
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config || \
        :;

# Disable initial welcome window
RUN sudo bash -c 'echo "X-GNOME-Autostart-enabled=false" >> /etc/xdg/autostart/gnome-initial-setup-first-login.desktop'

# Default command to start rdp server
CMD rm -f /var/run/xrdp/xrdp*.pid >/dev/null 2>&1; \
    service dbus restart >/dev/null 2>&1; \
    /usr/lib/systemd/systemd-logind >/dev/null 2>&1 & \
    [ -f /usr/sbin/sshd ] && /usr/sbin/sshd; \
    xrdp-sesman --config /etc/xrdp/sesman.ini; \
    xrdp --nodaemon --config /etc/xrdp/xrdp.ini


# Change apt repo to ones in South Korea
# RUN sed -i 's/archive.ubuntu.com/ftp.kaist.ac.kr/g' /etc/apt/sources.list

# update and upgrade libs
RUN apt update \
    && apt-get -y upgrade \
    && rm -rf /tmp/*

# Install basics 
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
RUN truncate -s0 /tmp/preseed.cfg && \
   (echo "tzdata tzdata/Areas select Asia" >> /tmp/preseed.cfg) && \
   (echo "tzdata tzdata/Zones/Asia select Seoul" >> /tmp/preseed.cfg) && \
   debconf-set-selections /tmp/preseed.cfg && \
   rm -f /etc/timezone && \
   apt-get install -y sudo tzdata build-essential gfortran automake \
   bison flex libtool git wget software-properties-common
## cleanup of files from setup
RUN rm -rf /tmp/*

# Install Utilities
RUN apt-get -y install x11-apps mesa-utils xauth \
    && rm -rf /tmp/*

# --------   ROS INSTALLATION   -------- #
# Locale for UTF-8
RUN apt-get -y install locales \
    && rm -rf /tmp/*
RUN locale-gen en_US en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Set source codes
RUN apt-get -y install software-properties-common && \
    add-apt-repository universe && \
    rm -rf /tmp/*
RUN apt-get update && apt-get -y install curl && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    rm -rf /tmp/*
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && apt-get -y upgrade && rm -rf /tmp/*

# Install ROS 2 Package
RUN apt-get -y install ros-jazzy-desktop-full ros-dev-tools ros-jazzy-ros-gz
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

# --------   GAZEBO INSTALLATION   -------- #
# Install dependency packages
RUN apt-get -y install python3-pip lsb-release gnupg curl git && \
    rm -rf /tmp/*

# Install dependency libraries
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list >/dev/null && \
    apt-get update && apt-get -y upgrade && rm -rf /tmp/*

# Install Gazebo Harmonic binary
RUN apt -y install gz-harmonic

# ------------ SET-UP A USER ------------- #
# Make user (assume host user has 1000:1000 permission)
# RUN adduser --shell /bin/bash --disabled-password --gecos "" user \
#     && echo 'user:user' | chpasswd && adduser user sudo \
#     && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# Set User as user
# USER ioes

# Use software rendering for container
ENV LIBGL_ALWAYS_INDIRECT=1

# Local setting for UTF-8
ENV LANG=en_US.UTF-8

# Set-up ROS Environment as default
RUN echo "" >> ~/.bashrc && \
    echo "# Set ROS Environment alive" >> ~/.bashrc && \
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

# RUN mkdir /home/$USER/.config && \
#     echo "yes" >> /home/$USER/.config/gnome-initial-setup-done

# Set-up Gazebo Environment as default
# RUN echo "" >> ~/.bashrc && \
#     echo "# Automatic set-up of the Gazebo in /gazebo" >> ~/.bashrc && \
#     echo "source /gazebo/install/setup.bash" >> ~/.bashrc

# To Build
# docker build -t jazzy-harmonic-rdp -f jazzy-harmonic-rdp.dockerfile .
# To Run
# docker run -it -p 3389:3389 -p 22:22 jazzy-harmonic-rdp