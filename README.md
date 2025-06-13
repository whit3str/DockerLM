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
*   **Direct License Usage**: Uses the provided `license.dat` directly, requiring manual pre-configuration by the user for the specific container environment (hostname, MAC, ports, daemon path).
*   **Log Rotation**: Automatic rotation and archiving of vendor-specific log files.
*   **Simplified Deployment**: Easier setup using Docker Compose with an `.env` file.

## Prerequisites

*   **Docker and Docker Compose**: Ensure Docker and Docker Compose are installed on your system.
*   **Vendor Files**: You will need:
    1.  Your FlexLM compatible license file, **which must be named `license.dat`**.
    2.  The corresponding vendor daemon executable (e.g., `myvendor`).
    *   These files should be placed in local directories as described in the [Vendor Specific Files](#vendor-specific-files) section.

## Configuration via Environment Variables

The following environment variables are used to configure the DockerLM V2 container. These can be set in an `.env` file when using Docker Compose, or via `-e` flags with `docker run`.

| Variable          | Default Value        | Description                                                                                                                               |
|-------------------|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `VENDOR_NAME`     | `default_vendor`     | The name of your FlexLM vendor (e.g., `ansys`, `adskflex`, `xilinxd`). This determines log file names and the vendor daemon executable name. |
| `LMGRD_PORT`      | `27000`              | The port number for the main `lmgrd` (FlexLM) daemon. This port will be exposed on the host by Docker. **You must ensure the `SERVER` line in your `license.dat` correctly specifies this port.** |
| `VENDOR_PORT`     | `27001`              | The port number for your specific vendor daemon. This port will be exposed on the host by Docker. **You must ensure the `VENDOR` line for your daemon in `license.dat` correctly specifies this port.** |
| `MAC_ADDRESS`     | `00:11:22:33:44:55`  | The MAC address to be set for the container by Docker (used as HOSTID). Use the format `XX:XX:XX:XX:XX:XX`. **You must ensure the `SERVER` line in your `license.dat` uses this MAC address as the HOSTID, or a compatible HOSTID like `ANY` if your license supports it.** |
| `HOSTNAME`        | `flexlm-server`      | The hostname to be set for the container by Docker. **You must ensure the `SERVER` line in your `license.dat` correctly references this hostname.** |
| `MAX_LOG_SIZE_MB` | `100`                | The maximum size (in MB) for the vendor-specific log file before it is rotated and archived.                                              |

## Vendor Specific Files

To use DockerLM, you need to provide your specific `license.dat` file and the vendor daemon executable.

**1. License File:**
*   Your license file **must be named `license.dat`**.
*   Place it in a local directory (e.g., `./my_flexlm_data/license_files/`).
*   This directory (or the file itself) will be mounted to make the license available at `/opt/flexlm/licenses/license.dat` inside the container.

**2. Vendor Daemon Executable:**
*   Place your vendor daemon executable (which should be named exactly as your `VENDOR_NAME`) directly in your local vendor daemons directory (e.g., `./my_flexlm_data/vendor_daemons/`). For example, if `VENDOR_NAME=myvendor`, then the executable named `myvendor` should be at `./my_flexlm_data/vendor_daemons/myvendor`.
    *   `<VENDOR_NAME>`: The value you set for the `VENDOR_NAME` environment variable (e.g., `ansys`, `adskflex`). This will be the name of your executable file.
*   This local directory (e.g., `./my_flexlm_data/vendor_daemons/`) will be mounted to `/opt/flexlm/vendors/` inside the container.
*   The script will look for the daemon at `/opt/flexlm/vendors/<VENDOR_NAME>`.
*   **Important: You are responsible for ensuring all details within your `license.dat` file are correct for the container environment before starting the service. The script no longer modifies this file.** This includes:
    *   The `SERVER` line: Must correctly specify the hostname (matching the container's `HOSTNAME`), the MAC address/HostID (matching the container's `MAC_ADDRESS` or using a compatible ID like `ANY`), and the lmgrd port (matching `LMGRD_PORT`).
    *   The `VENDOR` line: Must correctly specify the path to the vendor daemon as `/opt/flexlm/vendors/<VENDOR_NAME>` (where `<VENDOR_NAME>` is your actual vendor name) and the vendor port (matching `VENDOR_PORT`).

**Example Local Directory Structure (`./my_flexlm_data/`):**
```
./my_flexlm_data/
├── license_files/
│   └── license.dat              # Your license file for the current vendor
├── vendor_daemons/
│   └── <VENDOR_NAME>            # The vendor daemon executable, e.g., ansys (if VENDOR_NAME=ansys)
└── logs/                        # For logs (created/used by container)
    └── archive/                 # For archived logs
```
If `VENDOR_NAME=ansys`, the container expects:
*   License file: `/opt/flexlm/licenses/license.dat` (mounted from `./my_flexlm_data/license_files/license.dat`)
*   Vendor daemon: `/opt/flexlm/vendors/ansys` (mounted from `./my_flexlm_data/vendor_daemons/ansys`)

The entrypoint script will automatically make the vendor daemon executable.
[See existing vendor examples here](https://github.com/whit3str/DockerLM/tree/main/vendors) (Note: for V2, extract the daemon and license (renaming it to `license.dat`) and place them into the new structure described above).

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
3.  Create a `docker-compose.yml` file (you can copy the one from this repository). Ensure the `volumes` section correctly maps your local data directories, for example, using a base directory like `./my_flexlm_data`:
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
          # Mount your license.dat file (must be named license.dat)
          - ./my_flexlm_data/license_files/license.dat:/opt/flexlm/licenses/license.dat:ro
          # Alternatively, mount the directory containing license.dat:
          # - ./my_flexlm_data/license_files:/opt/flexlm/licenses:ro

          # Mount your local directory containing vendor daemon executables.
          # The executable file itself should be named after your VENDOR_NAME.
          # e.g., if VENDOR_NAME=myvendor, then my_flexlm_data/vendor_daemons/myvendor should be the executable file.
          - ./my_flexlm_data/vendor_daemons:/opt/flexlm/vendors:ro

          # Mount a local directory for persistent logs
          - ./my_flexlm_data/logs:/opt/flexlm/logs

          # Note: The license.dat file is used directly by FlexLM.
          # Ensure it is correctly pre-configured for the container's
          # environment (hostname, MAC address/HOSTID, ports, and vendor daemon path).
        restart: unless-stopped
        cap_add:
          - NET_ADMIN # Required for some FlexLM functionalities
    ```
4.  Prepare your `license.dat` and vendor daemon executable in your local directories (e.g., `./my-flexlm-server/my_flexlm_data/license_files/license.dat` and `./my-flexlm-server/my_flexlm_data/vendor_daemons/<VENDOR_NAME>`) as described under "Vendor Specific Files". (Note: `<VENDOR_NAME>` here is the executable file itself).
5.  Run `docker-compose up -d`.

### Using Docker Run

```bash
# Create local directories first
# For the vendor daemon, if VENDOR_NAME=myvendor, create ./my_flexlm_data/vendor_daemons/ and place the 'myvendor' executable inside it.
mkdir -p ./my_flexlm_data/license_files ./my_flexlm_data/vendor_daemons ./my_flexlm_data/logs

# Place your license.dat in ./my_flexlm_data/license_files/license.dat
# Place your vendor daemon (e.g., a file named 'myvendor') in ./my_flexlm_data/vendor_daemons/myvendor (assuming VENDOR_NAME=myvendor)

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
  -v ./my_flexlm_data/license_files/license.dat:/opt/flexlm/licenses/license.dat:ro \
  -v ./my_flexlm_data/vendor_daemons:/opt/flexlm/vendors:ro \
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
*   **License File Content**: Ensure your `license.dat` file is fully and correctly pre-configured for the vendor daemon version and the intended container environment (hostname, MAC/HostID, ports, daemon path). The script does not modify this file.
*   **Client Side**: Client machines need to be able to resolve the `HOSTNAME` of the license server to its IP address and reach the specified ports. You might need to update client license files or environment variables (e.g., `LM_LICENSE_FILE=@my-license-server`) and ensure network connectivity. For testing, you can add an entry to the client's hosts file:
    UNIX : `sudo nano /etc/hosts` (add `<server_ip> my-license-server`)
    WIN : Edit `C:\Windows\System32\drivers\etc\hosts` (add `<server_ip> my-license-server`)

## Resources

*   About FlexLM/FlexNet Publisher: [Flexera Community](https://community.flexera.com/t5/FlexNet-Publisher-Knowledge-Base/Welcome-FlexNet-Publisher-newcomers/ta-p/201836)
```
