# <h1 align="center">Docker Networking</a>

### Docker Network Types Review

__Bridge Network__:

<br><br>
<img src="https://github.com/digitalake/docker-networking/assets/109740456/cf5a77f5-970f-4859-8fea-ef3cdf72fd31" width="400"> 
<br><br>

`Description`: Bridge network is the default network mode in Docker. When you create a container, it is attached to a bridge network by default, and Docker provides a private internal IP address to the container.

`Differences`: Containers on a bridge network can communicate with each other using their internal IP addresses. This network type provides network isolation and enables port mapping to allow containers to communicate with the host and external networks. However, by default, containers on a bridge network cannot communicate with containers in other bridge networks.

`Use Cases`:

- Running multiple containers on the same host that need to communicate with each other.
- Running web applications where you want to expose specific container ports to the host or external networks.
- Provides a good balance between isolation and connectivity.

__Host Network__:

<br><br>
<img src="https://github.com/digitalake/docker-networking/assets/109740456/c008b23a-b9bd-4e26-aa83-55614b66506a" width="300"> 
<br><br>

`Description`: When a container is attached to the host network, it uses the network stack of the host directly. This means the container shares the host's network namespace.

`Differences`: Containers on the host network mode have no network isolation from the host itself, and they can use the host's IP address. This mode provides the best network performance but sacrifices isolation.

`Use Cases`:

- Situations where you need maximum network performance, and network isolation is not a concern.
- Debugging network-related issues within containers.
- When you want containers to access network services running on the host directly.

__Overlay Network__:

<br><br>
<img src="https://github.com/digitalake/docker-networking/assets/109740456/3f2ac582-cae1-4f54-92ef-f1a4e6dc0db2" width="470"> 
<br><br>

`Description`: Overlay network is used in Docker Swarm mode for creating networks that span multiple Docker nodes. It enables containers on different hosts to communicate with each other securely.

`Differences`: Overlay networks are primarily used in clustered Docker environments. They provide network isolation and security between containers running on different nodes. Overlay networks use a key-value store to manage network configuration across nodes.

`Use Cases`:

- Deploying applications in a distributed, multi-node Docker Swarm cluster.
- Running microservices where containers need to communicate across different hosts.
- Ensuring secure communication between containers in a multi-host environment.

### Network types in action

__Bridge Network__


Created simple Docker Compose file [code link](https://github.com/digitalake/docker-networking/blob/main/docker/docker-compose.yml) for showing `Bridge Network`:

```
---
version: "3.8"
services:
  front:
    build: .
    container_name: front 
    restart: on-failure
    networks:
      - backend
      - frontend
  back:
    build: .
    container_name: back
    restart: on-failure 
    networks:
      - backend
      
networks:
  backend:
    driver: bridge
    internal: true
  frontend:
    driver: bridge
```

After running `docker-compose up -d`, two containers are launched:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/cfbfba11-81c7-4910-bc75-609fc2916b7e" width="800"> 

`Front container` is connected to the Internet with `External Bridge` network and also connected to the backend network. While `Back container` is isolated inside `Internal Bridge` network and can communicate only with the `Front container`

Pinging `Front-->Back`

<img src="https://github.com/digitalake/docker-networking/assets/109740456/897c8712-e75f-4409-8dd2-ac999bb06996" width="500"> 

Pinging `Front-->Internet`

<img src="https://github.com/digitalake/docker-networking/assets/109740456/97b6cd7b-6f2b-4c85-bd9f-af7f9cdf2aa7" width="500">

Pinging `Back-->Front`

<img src="https://github.com/digitalake/docker-networking/assets/109740456/ba0e6e23-fcc0-4fbc-9a87-f54f991a22a4" width="500">

Pinging `Back-->Internet`

<img src="https://github.com/digitalake/docker-networking/assets/109740456/8323776c-59c2-437c-8cd0-106e50227151" width="400"> 

__Host Network__

There is nothing specific here so we can, for example, run some NginX web-server using `Host` network.

Running a container with `Host` network:
```
docker run --rm -d --network=host --name container-host nginx:mainline-alpine3.18-slim
```

<img src="https://github.com/digitalake/docker-networking/assets/109740456/15615a68-463d-43a3-9a71-3c9fecc7b813" width="900"> 

NginX is running on `80-tcp` port, so we can check:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/07b3d1f4-45e0-411e-b00a-183d784867f3" width="500"> 

__Overlay Network__

Let's take a look at the `Overlay` network used for Docker Swarm cluster. For such purpose, we need to create VMs and setup the Docker Swarm cluster.  

I prepared Terraform code for creating a group of VMs locally ([Terraform Libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs) provired was used). Terraform uses cloudinit config to setup ssh keys and install qemu-agents for getting information about VM's ip-adresses. Also Terraform generates Ansible inventory right into Ansible directory of this project.

To execute Terraform code, `terraform.tfvars` file needs to be provided. An example (was used for this task):

```
# terraform.tfvars

base_image_location = "/home/vanadium/libvirt/img/jammy-server-cloudimg-amd64.img"

pool_dir = "/home/vanadium/libvirt/pool_storage"

#Virtual machines setup inputs
vms = {
  master = {
    memoryMB            = 1024 * 2,
    cpu                 = 2,
    libvirt_volume_size = 1024 * 1024 * 1024 * 20
  },
  worker1 = {
    memoryMB            = 1024 * 2,
    cpu                 = 2,
    libvirt_volume_size = 1024 * 1024 * 1024 * 10
  }
  worker2 = {
    memoryMB            = 1024 * 2,
    cpu                 = 2,
    libvirt_volume_size = 1024 * 1024 * 1024 * 10
  }
}
```

With such configuration, after the succesful `terraform apply`, 3 VMs will be created:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/9c13610f-3e0a-4117-84e8-cc8380b15236" width="600"> 

Also we can see them running with VirtManager UI:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/65331508-53e0-4793-91bc-3fec31a9d99e" width="150"> 

Now it's time to  run Ansible:

```
ansible-playbook -i inventory -u deployer --private-key ~/.ssh/key swarm_formation.yml
```

This playbook calls two roles: `docker-setup` (installs Docker and some modules) and `swarm_setup` (Initializes Swarm on the Master node and registers Worker nodes based on provided `inventory` file)

<img src="https://github.com/digitalake/docker-networking/assets/109740456/43b87516-37bb-43af-b22c-c36092b507f1" width="350"> 

Swarm is initialized at Manager, no additional Managers were detected and all the Workers were registered to the Swarm cluster. 

<img src="https://github.com/digitalake/docker-networking/assets/109740456/cf0bcb2a-6344-4df9-8ee2-53febd0caceb" width="800"> 

Now we can use a simple Composefile to deploy some services from Manager node creating separated `Overlay` network (global mode means deploying the service on eachnode of the cluster):

```
# demo.yml
version: '3' 

services:
  web:
    image: nginx
    deploy:
      mode: global

networks:
  mynetwork:
    driver: overlay
```

```
docker stack deploy -c demo.yml myapp
```

As the result, 3 service replicas were created:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/f049b0d9-79f9-4310-8ad4-e7a3adf28af9" width="500">

Service replicas are running on different Docker hosts, using newly created `Overlay` network:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/9a87804a-ea49-43e1-a9ff-0dd8027712cc" width="500"> 

Inspecting the `Overlay` network:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/10dca756-280f-44f5-98e3-03352543f65b" width="750"> 

Networks for Manager replica:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/0e9be69d-d0b7-4637-b50e-0e478b260879" width="700"> 

Networks for Worker replica:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/13b8be05-c277-4a33-8571-0e2d05e7eb10" width="700"> 

So it's possible to run `ping` using `Overlay` adresses:

<img src="https://github.com/digitalake/docker-networking/assets/109740456/331911d2-a7b8-4959-a40a-75c57c071ff0" width="500"> 
