# DockerLM

DockerLM is a containerized app of the FlexLM tool, allowing you to host a license server in a container.

## Prerequisites

What things you need to install the software and how to install them.

```
Docker
A license file FlexLM compatible
The MAC Address relative to the hostname/license file.
Docker Compose support implentation to be done.
```

## Deployment

Clone the project and run the following command
```
cd /DockerLM && docker run --hostname HOSTNAME --user root --mac-address="MAC@" --name dockerlm -it dockerlm:latest
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
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Listening port: VENDOPORT`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Daemon select timeout (in seconds): 1`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@)`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) === Host Info ===`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Host used in license file: HOSTNAME`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) HostID node-locked in license file: MAC@`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) HostID of the License Server: MAC@`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) Running on Hypervisor: Unknown Hypervisor`\
` 9:32:04 (VENDOR) (@VENDOR-SLOG@) ===============================================`\

## Resources

About FlexLM : https://community.flexera.com/t5/FlexNet-Publisher-Knowledge-Base/Welcome-FlexNet-Publisher-newcomers/ta-p/201836


