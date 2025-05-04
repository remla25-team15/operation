## Docker Compose setup

This project is managed from the `operation/` directory using Docker Compose. It orchestrates multiple services across repositories.

### Expected directory structure

The expected directory layout is as follows:

```zsh
.
├── operation/                # Entry point with docker-compose files
│   ├── docker-compose.yml
│   └── docker-compose.override.yml (used in development)
├── app-frontend/            # Frontend (UI)
├── app-service/             # Flask Backend API
├── lib-ml/                  # Shared ML utilities
├── lib-version/             # Versioning logic
├── model-service/           # Model loading/inference logic
└── model-training/          # Model training pipeline
```

All sibling directories are mounted or built as needed from the operation/ context.

## Running in Production

To run the application using prebuilt images (from GitHub Container Registry):

```zsh
cd operation
docker compose -f docker-compose.yml up -d
```

This uses `docker-compose.yml` only and does not mount local code.

## Development

For local development, use the `docker-compose.override.yml` file. This override:

- Mounts local directories as volumes for live code updates
- Sets development environment variables

To run in development mode:

```zsh
cd operation
docker compose up --build
```

## Clean-up commands:

```zsh
docker compose down          # Stop and clean up
docker compose logs -f       # View logs
```
