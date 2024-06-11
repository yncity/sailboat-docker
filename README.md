# Communication between ROS2 Jazzy - Noble and ROS2 Humble - Jazzy

```bash
cd ROS-Gazebo-Dockerfile/docker-compose

# Build both image using humble-jammy.dockerfile and jazzy-noble.dockerfile
docker compose build

# Run both image at the same time as two separate containers
docker compose up

# Join humble image based running container
chmod +x join-humble.bash
./join-humble.bash
source /opt/ros/humble/setup.bash

# Join Jazzy imabe based running container
chmod +x join-jazzy.bash
./join-jazzy.bash
source /opt/ros/jazzy/setup.bash

# At seprate terminals with each joined into two separate containers
ros2 run demo_nodes_py talker
ros2 run demo_nodes_py listener

# Hurray!
```