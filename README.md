# DockerLM

DockerLM is a containerized app of the FlexLM tool, allowing you to host a license server in a container.

## Getting Started

Download links:

SSH clone URL: ssh://git@git.jetbrains.space/muzungo/main/DockerLM.git

HTTPS clone URL: https://git.jetbrains.space/muzungo/main/DockerLM.git

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

## Prerequisites

What things you need to install the software and how to install them.

```
Docker
Docker Compose
A license file FlexLM compatible
The MAC Address relative to the hostname/license file.
```

## Deployment

Clone the project and run the following command
```
cd /DockerLM && docker compose up -d
```
Inspect the container and ensure it's running normally :

`XX:XX:XX (VENDOR) TCP_NODELAY NOT enabled`
`XX:XX:XX (VENDOR) Listener Thread: running`
## Resources

About FlexLM : https://community.flexera.com/t5/FlexNet-Publisher-Knowledge-Base/Welcome-FlexNet-Publisher-newcomers/ta-p/201836


