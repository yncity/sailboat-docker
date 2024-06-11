FROM ros:humble

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

# Install demo ros package
RUN apt-get update && apt-get install -y \
      ros-humble-demo-nodes-cpp \
      ros-humble-demo-nodes-py && \
    rm -rf /var/lib/apt/lists/*

# Ardupilot installation


# setup entrypoint
COPY ./ros_entrypoint.sh /
RUN chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["/bin/bash"]

# # launch ros package
# CMD ["ros2", "launch", "demo_nodes_cpp", "talker_listener.launch.py"]
