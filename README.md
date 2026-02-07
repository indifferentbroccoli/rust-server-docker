<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/rust-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/rust-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/rust-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/rust-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/rust-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/rust-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/rust-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/rust-server-docker)

Game server hosting

Fast RAM, high-speed internet

Eat lag for breakfast

[Try our Rust Server hosting free for 2 days!](https://indifferentbroccoli.com/rust-server-hosting)

# Rust Server Docker

> [!IMPORTANT]
> Using Docker Desktop with WSL2 on Windows will result in a very slow download!

## Server Requirements

| Resource | Minimum | Recommended                             |
|----------|---------|-----------------------------------------|
| CPU      | 4 cores | 4+ cores                                |
| RAM      | 8GB     | Recommend over 12GB for stable operation |
| Storage  | 20GB    | 30GB                                    |

## How to use

> [!IMPORTANT]
> .env settings will override the current settings in the server configuration
> If you do not want that to happen, set GENERATE_SETTINGS=false

Copy the .env.example file to a new file called .env file. Then use either `docker compose` or `docker run`

### Docker compose

Starting the server with Docker Compose:

```yaml
services:
  rust:
    image: indifferentbroccoli/rust-server-docker
    restart: unless-stopped
    container_name: rustserver
    stop_grace_period: 30s
    ports:
      - 28015:28015
      - 28015:28015/udp
      - 28016:28016
      - 28016:28016/udp
      - 28082:28082
    environment:
      GENERATE_SETTINGS: true
    env_file:
      - .env
    volumes:
      - ./server-files:/steamcmd/rust
```

Then run:

```bash
docker-compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name rustserver \
    --stop-timeout 30 \
    -p 28015:28015 \
    -p 28015:28015/udp \
    -p 28016:28016 \
    -p 28016:28016/udp \
    -p 28082:28082 \
    -e GENERATE_SETTINGS=true \
    --env-file .env \
    -v ./server-files:/steamcmd/rust \
    indifferentbroccoli/rust-server-docker
```

## Environment Variables

You can use the following values to change the settings of the server on boot.
It is highly recommended you set the following environment values before starting the server:

* RCON_PASSWORD

| Variable                                          | Default                                                       | Info                                                                                                                                                |
|---------------------------------------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|  
| PUID                                              | 1000                                                          | User ID for file permissions. Run `id -u` to get your user ID                                                                                      |
| PGID                                              | 1000                                                          | Group ID for file permissions. Run `id -g` to get your group ID                                                                                    |
| SERVER_NAME                                       | rustserver                                                    | The name of your Rust server as it appears in the server browser                                                                                   |
| SERVER_DESCRIPTION                                | Welcome to your Indifferent Broccoli Rust server              | The description shown in the server browser                                                                                                         |
| SERVER_SEED                                       | 12345                                                         | World generation seed. Same seed = same map                                                                                                         |
| WORLD_SIZE                                        | 3500                                                          | Size of the world map (3000-6000 recommended)                                                                                                       |
| MAX_PLAYERS                                       | 50                                                            | Maximum number of players that can connect to the server                                                                                            |
| SERVER_PORT                                       | 28015                                                         | Game port for player connections                                                                                                                    |
| RCON_PORT                                         | 28016                                                         | The port for RCON (Remote Console) access                                                                                                          |
| APP_PORT                                          | 28082                                                         | The port for the Rust+ companion app                                                                                                                |
| RCON_PASSWORD                                     | admin                                                         | Password for RCON access - CHANGE THIS!                                                                                                            |
| OXIDE_ENABLED                                     | false                                                         | Enable Oxide/uMod plugin framework                                                                                                                  |
| UPDATE_ON_START                                   | true                                                          | If set to false, skips downloading and validating server files from Steam on startup                                                                |
| PVP                                               | true                                                          | Enable PvP combat                                                                                                                                   |
| SERVER_HEADERIMAGE                                |                                                               | HTTP link to a custom header image for the server browser                                                                                          |
| SERVER_URL                                        |                                                               | Website URL for your server                                                                                                                         |
| DECAY_SCALE                                       | 1.0                                                           | Scale for structure decay (0 = no decay, 1 = default)                                                                                              |
| STABILITY                                         | true                                                          | Enable structure stability system                                                                                                                   |
| SAVE_INTERVAL                                     | 600                                                           | Server save interval in seconds                                                                                                                     |
| RADIATION                                         | true                                                          | Enable radiation in radtowns                                                                                                                        |

> [!NOTE]
> Additional startup arguments can be configured via RUST_STARTUP_ARGUMENTS environment variable

## RCON

This container includes the RCON CLI tool for server management. You can execute RCON commands like:

```bash
docker exec rustserver rcon-cli status
docker exec rustserver rcon-cli "say Hello Players!"
```

## Volumes

* `/steamcmd/rust` - Server files, game data, and configuration
## Ports

* `28015` - Game Port (TCP/UDP)
* `28016` - RCON Port (TCP/UDP)
* `28082` - Rust+ App Port (TCP)

## Building the image

To build the image yourself:

```bash
docker build -t rust-server-docker .
```

## Support

For issues and questions, please visit:

- [GitHub Issues](https://github.com/indifferentbroccoli/rust-server-docker/issues)
- [Discord Community](https://discord.gg/indifferentbroccoli)
- [Website](https://indifferentbroccoli.com)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
