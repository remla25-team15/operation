# How to run?

To provision, orchestrate, and run the application using a Kubernetes deployment across multiple VMs, you can run:

```zsh
./scripts/run-all.sh
```

If you're running it for the first time, the model-service will download the models to cache them locally.
It takes a while so you can go grab a cup of coffee or something... :coffee:

The next invocations should be faster though.

Unfortunately, all the scripts are bash scripts so you will have to run them in bash (or z shell).
If you're using Windows, you can still download and use bash (maybe try using git bash).
If you're stuck with Powershell... helaas pindakaas...

# Particulars

## Docker Compose setup

This project is managed from the `operation/` directory using Docker Compose. It orchestrates multiple services across repositories.

# Running in Production

To run the application using prebuilt images (from GitHub Container Registry):

```zsh
cd operation
docker compose -f docker-compose.yml up -d
```

This uses `docker-compose.yml` only and does not mount local code.

The application should be accessible at [http://localhost:8080](http://localhost:8080)

## Provisioning Setup

You can set up the VMs and provision them using the `scripts/run-provisioning.sh` script.

```zsh
./scripts/run-provisioning.sh
```

This script runs all necessary vagrant commands and then proceeds to provision the VMs.

After provisioning is successful, you need to add the kubernetes dashboard IP to your `/etc/hosts` so we can access it locally.
To do this, you can run:

```zsh
./scripts/update-dashboard-hosts.sh
```

The Dashboard will then be accessible at: [https://dashboard.local/](https://dashboard.local/)

To access the Dashboard, you need a bearer token. You can generate it by running the following command:

```zsh
kubectl -n kubernetes-dashboard create token admin-user
```

Copy and paste this token to access the dashboard.

#### More info:

Provisioning is done through the `/provisioning/` folder. The
corresponding README can be found [here](https://github.com/remla25-team15/operation/tree/main/provisioning)

> Note: To do provisioning manually, please make sure you `cd` into `provisioning/` folder

## Kubernetes Setup

After you're done provisioning the VMs, you can, again, run a simple script to deploy all the kubernetes manifests:

```zsh
./scripts/run-manifests.sh
```

Or, you can also do it manually:

```zsh
kubectl apply -f ./k8s/ --recursive
```

> Note that unlike provisioning, this command needs to be run from the root folder

Now, the application should be accessible at [http://app.local/](http://app.local/)

If something goes wrong, it's probably because the scripts silently errored out. In this case,
please perform everything manually as per the respective READMEs or sections to identify which step is
causing issues.

# Development Section

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

For local development, use the `docker-compose.override.yml` file. This override:

- Builds images for the services locally
- Mounts local directories as volumes for live code updates
- Sets development environment variables

To run in development mode:

```zsh
cd operation
docker compose up --build
```

The application should be accessible at [http://localhost:8080](http://localhost:8080)

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
