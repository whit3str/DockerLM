# DockerLM V2: Environment Variable Driven FlexLM Server

DockerLM is a containerized application of the FlexLM (FlexNet Publisher) license management tool, allowing you to easily host a license server within a Docker container. This V2 has been enhanced to be primarily configured via environment variables for greater flexibility and ease of use.

<!-- TOC -->
* [DockerLM V2: Environment Variable Driven FlexLM Server](#dockerlm-v2-environment-variable-driven-flexlm-server)
  * [Key Features of V2](#key-features-of-v2)
  * [Prerequisites](#prerequisites)
  * [Configuration via Environment Variables](#configuration-via-environment-variables)
  * [Vendor Specific Files](#vendor-specific-files)
  * [Deployment](#deployment)
    * [Using Docker Compose (Recommended)](#using-docker-compose-recommended)
    * [Using Docker Run](#using-docker-run)
  * [Log Management](#log-management)
  * [Verifying Server Status](#verifying-server-status)
  * [Troubleshooting](#troubleshooting)
  * [Resources](#resources)
<!-- TOC -->

## Key Features of V2

*   **Dynamic Configuration**: Most settings are controlled via environment variables.
*   **Vendor Agnostic**: Easily switch between different FlexLM vendors.
*   **Automated License Modification**: Hostname, MAC address, and ports in the license file are updated automatically based on environment variables.
*   **Log Rotation**: Automatic rotation and archiving of vendor-specific log files.
*   **Simplified Deployment**: Easier setup using Docker Compose with an `.env` file.

## Prerequisites

*   **Docker and Docker Compose**: Ensure Docker and Docker Compose are installed on your system.
*   **Vendor Files**: You will need:
    1.  A FlexLM compatible license file (e.g., `myvendor.lic`) for your software.
    2.  The corresponding vendor daemon executable (e.g., `myvendor`).
    *   These files should be placed in a local directory structure as described in the [Vendor Specific Files](#vendor-specific-files) section.

## Configuration via Environment Variables

The following environment variables are used to configure the DockerLM V2 container. These can be set in an `.env` file when using Docker Compose, or via `-e` flags with `docker run`.

| Variable          | Default Value        | Description                                                                                                                               |
|-------------------|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `VENDOR_NAME`     | `default_vendor`     | The name of your FlexLM vendor (e.g., `ansys`, `adskflex`, `xilinxd`). This determines log file names and subdirectories for vendor files. |
| `LMGRD_PORT`      | `27000`              | The port number for the main `lmgrd` (FlexLM) daemon. This port will be exposed on the host.                                              |
| `VENDOR_PORT`     | `27001`              | The port number for your specific vendor daemon. This port will be exposed on the host.                                                   |
| `MAC_ADDRESS`     | `00:11:22:33:44:55`  | The MAC address (Host ID) to be written into the license file. Use the format `XX:XX:XX:XX:XX:XX`.                                       |
| `HOSTNAME`        | `flexlm-server`      | The hostname to be written into the license file and set for the container.                                                               |
| `MAX_LOG_SIZE_MB` | `100`                | The maximum size (in MB) for the vendor-specific log file before it is rotated and archived.                                              |

## Vendor Specific Files

To use DockerLM, you need to provide the license file and the vendor daemon executable. These files must be organized in a local directory (e.g., `./flexlm_data/vendors`) that you will mount into the container.

The expected structure within your local `./flexlm_data/vendors` directory is:
```
./flexlm_data/
├── vendors/
│   └── <VENDOR_NAME>/                 # A directory named after your vendor (e.g., ansys)
│       ├── <VENDOR_NAME>.lic          # The license file (e.g., ansys.lic)
│       └── <VENDOR_NAME>              # The vendor daemon executable (e.g., ansys)
└── logs/                              # This directory will be created/used for logs
    └── archive/                       # For archived logs
```
**Example:** If `VENDOR_NAME=ansys`, the container expects:
*   License file: `/opt/flexlm/vendors/ansys/ansys.lic` (mounted from `./flexlm_data/vendors/ansys/ansys.lic`)
*   Vendor daemon: `/opt/flexlm/vendors/ansys/ansys` (mounted from `./flexlm_data/vendors/ansys/ansys`)

The entrypoint script will automatically make the vendor daemon executable.
[See existing vendor examples here](https://github.com/whit3str/DockerLM/tree/main/vendors) (Note: for V2, you only need the `.lic` and daemon file from these examples, placed in your local directory as per the structure above).

## Deployment

### Using Docker Compose (Recommended)

1.  Create a directory for your FlexLM setup, e.g., `my-flexlm-server/`.
2.  Inside `my-flexlm-server/`, create an `.env` file with your desired configurations:
    ```env
    # my-flexlm-server/.env
    VENDOR_NAME=myvendor
    LMGRD_PORT=27000
    VENDOR_PORT=27001
    MAC_ADDRESS=00:1A:2B:3C:4D:5E # Replace with your actual MAC address
    HOSTNAME=my-license-server   # Choose a hostname
    MAX_LOG_SIZE_MB=50
    ```
3.  Create a `docker-compose.yml` file (you can copy the one from this repository). Ensure the `volumes` section correctly maps your local data directories:
    ```yaml
    # my-flexlm-server/docker-compose.yml
    version: '3.8' # Or newer
    services:
      dockerlm:
        image: ghcr.io/whit3str/dockerlm:latest # Or your locally built image: dockerlm:env
        container_name: ${VENDOR_NAME:-vendor}-flexlm
        ports:
          - "${LMGRD_PORT:-27000}:${LMGRD_PORT:-27000}"
          - "${VENDOR_PORT:-27001}:${VENDOR_PORT:-27001}"
        environment:
          - VENDOR_NAME=${VENDOR_NAME:-default_vendor}
          - LMGRD_PORT=${LMGRD_PORT:-27000}
          - VENDOR_PORT=${VENDOR_PORT:-27001}
          - MAC_ADDRESS=${MAC_ADDRESS:-00:11:22:33:44:55}
          - HOSTNAME=${HOSTNAME:-flexlm-server}
          - MAX_LOG_SIZE_MB=${MAX_LOG_SIZE_MB:-100}
        mac_address: ${MAC_ADDRESS:-00:11:22:33:44:55} # Docker setting for container MAC
        hostname: ${HOSTNAME:-flexlm-server}          # Docker setting for container hostname
        volumes:
          # Mount your local vendors directory to /opt/flexlm/vendors in the container
          # The entrypoint script expects license and daemon here, under a $VENDOR_NAME subfolder
          - ./flexlm_data/vendors:/opt/flexlm/vendors:ro
          # Mount a local directory for persistent logs
          - ./flexlm_data/logs:/opt/flexlm/logs
          # Note: The original license file in /opt/flexlm/vendors is read-only.
          # A processed copy is created in /opt/flexlm/licenses (inside the container) for lmgrd to use.
        restart: unless-stopped
        cap_add:
          - NET_ADMIN # Required for some FlexLM functionalities
    ```
4.  Prepare your vendor files in `./my-flexlm-server/flexlm_data/vendors/<VENDOR_NAME>/` as described above.
5.  Run `docker-compose up -d`.

### Using Docker Run

```bash
# Create local directories first
mkdir -p ./my_flexlm_data/vendors ./my_flexlm_data/logs

# Place your vendor files in ./my_flexlm_data/vendors/myvendor/myvendor.lic and ./my_flexlm_data/vendors/myvendor/myvendor

docker run -d \
  --name myvendor-flexlm \
  -p 27000:27000 \
  -p 27001:27001 \
  -e VENDOR_NAME="myvendor" \
  -e LMGRD_PORT="27000" \
  -e VENDOR_PORT="27001" \
  -e MAC_ADDRESS="00:1A:2B:3C:4D:5E" \
  -e HOSTNAME="my-license-server" \
  -e MAX_LOG_SIZE_MB="50" \
  --mac-address="00:1A:2B:3C:4D:5E" \
  --hostname="my-license-server" \
  -v ./my_flexlm_data/vendors:/opt/flexlm/vendors:ro \
  -v ./my_flexlm_data/logs:/opt/flexlm/logs \
  --cap-add=NET_ADMIN \
  ghcr.io/whit3str/dockerlm:latest # Or your locally built image
```
Remember to replace placeholder values with your actual data.

## Log Management

*   The main log file for the vendor daemon will be located at `/opt/flexlm/logs/<VENDOR_NAME>.log` inside the container (and in your mounted `./flexlm_data/logs/` directory).
*   When this log file reaches the size specified by `MAX_LOG_SIZE_MB`, it will be automatically archived.
*   Archived logs are moved to `/opt/flexlm/logs/archive/<VENDOR_NAME>.log.<timestamp>` (e.g., `./flexlm_data/logs/archive/`).

## Verifying Server Status

You can check the logs of the running container:
`docker logs <container_name_or_id>` (e.g., `docker logs myvendor-flexlm`)

Look for messages indicating that `lmgrd` and the vendor daemon have started successfully. The example output in the original README showing vendor daemon logs is still relevant for what to look for.

## Troubleshooting

*   **Permissions**: Ensure the vendor daemon file you provide has execute permissions. The entrypoint script attempts to `chmod +x` it, but initial permissions can matter.
*   **Firewall**: Ensure your host firewall allows traffic on `LMGRD_PORT` and `VENDOR_PORT`.
*   **License File Content**: While the script updates key fields, ensure your base license file is valid for the vendor daemon version.
*   **Client Side**: Client machines need to be able to resolve the `HOSTNAME` of the license server to its IP address and reach the specified ports. You might need to update client license files or environment variables (e.g., `LM_LICENSE_FILE=@my-license-server`) and ensure network connectivity. For testing, you can add an entry to the client's hosts file:
    UNIX : `sudo nano /etc/hosts` (add `<server_ip> my-license-server`)
    WIN : Edit `C:\Windows\System32\drivers\etc\hosts` (add `<server_ip> my-license-server`)

## Resources

*   About FlexLM/FlexNet Publisher: [Flexera Community](https://community.flexera.com/t5/FlexNet-Publisher-Knowledge-Base/Welcome-FlexNet-Publisher-newcomers/ta-p/201836)
```
