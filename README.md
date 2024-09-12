# DockerLM

DockerLM is a containerized app of the FlexLM tool, allowing you to host a license server in a container.

<!-- TOC -->
* [DockerLM](#dockerlm)
  * [Prerequisites](#prerequisites)
  * [Deployment](#deployment)
    * [Docker Run](#docker-run-)
    * [Docker Compose](#docker-compose)
  * [Resources](#resources)
<!-- TOC -->
## Prerequisites

Needed stuff to get the image working :
* Docker
* A license file FlexLM compatible : license.dat : \
Ensure HOSTNAME is correct.\
Ensure VENDOR name and path are correct and declared\
[List of compatible vendors](https://github.com/whit3str/DockerLM/tree/main/vendors)
* The MAC@ relative to the hostname/license file.
* The PORT to expose.

## Deployment

### Docker Run 
Clone the project and run the following command\
`
cd /DockerLM && docker run -v /path/to/license.dat:/opt/license.dat --hostname HOSTNAME --mac-address="MAC@" -p LMGRDPORT:LMGRDPORT -p VENDORPORT:VENDORPORT --name dockerlm_VENDOR -it ghcr.io/whit3str/dockerlm:latest
`
### Docker Compose

```
version: '3.9'
services:
    dockerlm:
        image: 'ghcr.io/whit3str/dockerlm:latest'
        tty: true
        stdin_open: true
        container_name: dockerlm_VENDOR #Optional, specify if you aim to run several containers
        ports:
            - 'LMGRDPORT:LMGRDPORT'
            - 'VENDORPORT:VENDORPORT'
        networks:
            default:
                mac_address: MAC@ #Fill correct value
        hostname: HOSTNAME #Fill correct value
        volumes:
            - '/path/to/license.dat:/opt/license.dat' #UNIX PATH
```
Inspect the container and ensure it's running normally :

` 9:32:04 (VENDOR) (@VENDOR-SLOG@) === Vendor Daemon ===`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Vendor daemon: VENDOR`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Start-Date: Mon Sep 09 2024 09:32:04 UTC`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) PID: 10`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) VD Version: v11.16.3.0 build 246844 x64_lsb ( build 246844 (ipv6))`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@)`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) === Startup/Restart Info ===`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Options file used: None`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Is vendor daemon a CVD: No`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Is FlexNet Licensing Service installed and compatible: No`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) FlexNet Licensing Service Version: -NA-`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Is TS accessed: No`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) TS access time: -NA-`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Number of VD restarts since LS startup: 0`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@)`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) === Network Info ===`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Listening port: VENDORPORT`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Daemon select timeout (in seconds): 1`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@)`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) === Host Info ===`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Host used in license file: HOSTNAME`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) HostID node-locked in license file: MAC@`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) HostID of the License Server: MAC@`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Running on Hypervisor: Unknown Hypervisor`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) ===============================================`

The License Server is UP, maybe not accessible, if facing issues declare the HOSTNAME of the License Server with the Docker host IP.\
UNIX : _/etc/hosts_\
WIN : _C:\Windows\System32\drivers\etc\hosts_
## Resources

About FlexLM : https://community.flexera.com/t5/FlexNet-Publisher-Knowledge-Base/Welcome-FlexNet-Publisher-newcomers/ta-p/201836


