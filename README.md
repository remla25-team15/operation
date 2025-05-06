## Docker Compose setup

This project is managed from the `operation/` directory using Docker Compose. It orchestrates multiple services across repositories.

### Expected directory structure for development

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

To clone the required services, please run

```zsh
./clone.sh
```

## Running in Production

To run the application using prebuilt images (from GitHub Container Registry):

```zsh
cd operation
docker compose -f docker-compose.yml up -d
```

This uses `docker-compose.yml` only and does not mount local code.

## Development

For local development, use the `docker-compose.override.yml` file. This override:

- Builds images for the services locally
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

## API Docs

API endpoints are provided by app-service and model-service.

You can access the API docs when running the application in development mode, i.e. `docker compose up --build`, (please refer the above
section for setting it up in dev) because
only app-frontend is accessible from host in production. These docs can be viewed by going to the respective urls after running the application:

app-service: [http://localhost:5000/apidocs](http://localhost:5000/apidocs)
model-service: [http://localhost:5001/apidocs](http://localhost:5001/apidocs)
