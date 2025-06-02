# How to run?

> Note: You cannot provision anything unless you set up SSH. Please generate your SSH keys and put them in the correct folder for the provisioning to work.
> You can find the instructions in the README inside `provisioning/` [here](https://github.com/remla25-team15/operation/tree/main/provisioning).

To provision, orchestrate, and run the application using a Kubernetes deployment across multiple VMs, you can run:

```zsh
./scripts/run-all.sh
```

Now, the application should be accessible at [http://app.local/](http://app.local/)

The script is robust and waits for some time until pods and services are available.
It does time out if it takes too long for services or pods to start.
Sometimes, it also times out during provisioning where we have waiting steps for components to get ready.
If the script exits because of a timeout related error, you can simply run it again, maybe using the `--provision` flag.

```zsh
./scripts/run-all.sh --provision
```

It should pick up from where it left off the last time.

Invoking the script again and again shouldn't cause any problems since most of the provisioning is idempotent.

If you're running it for the first time, the model-service will download the models to cache them locally in a shared
folder `provisioning/shared/` which is shared across all VMs and mounted in the container. This is persistent so
subsequent invocations will use this rather than downloading the model again whenever the container is re-created.

But, it takes a while so you can go grab a cup of coffee or something... :coffee:

The next invocations should be faster.

> Note: Our current deployment uses Istio gateway for app and kiali but still uses Ingress for kubernetes dashboard and grafana.
> When the script runs, please make sure you see something like this in your terminal:

```zsh
Current relevant entries in /etc/hosts after script execution:
192.168.56.80 app.local kiali.local prometheus.local
192.168.56.81 dashboard.local grafana.local
```

> Your /etc/hosts should have these entries (the IP addresses could be different). The `scripts/run-all.sh` script invokes `scripts/update-hosts.sh` script which
> should inject them automatically but if for some reason you cannot access the app or anything else, please make sure you have these entries in the /etc/hosts file.

Unfortunately, all the scripts are bash scripts so you will have to run them in bash (or z shell).
If you're using Windows, you can still download and use bash (maybe try using git bash).
If you're stuck with Powershell... helaas pindakaas...

The script should work correctly and you do not need to run any commands manually but if you want to do so, you can read further.

First, for managing kubernetes cluster from the host machine and running any `kubectl` commands,
you need to copy the kubernetes configuration from the controller node to the host machine and set the `KUBECONFIG` variable to point to it.

The following command should help with it:

```zsh
 cd provisioning/
 vagrant ssh ctrl -c "sudo cat /etc/kubernetes/admin.conf" > kubeconfig
 export KUBECONFIG=$(pwd)/kubeconfig
 cd ..
```

> You need to make sure to set this variable for every shell invocation, i.e. whenever you open a new shell, please make sure to set this
> before you try to run `kubectl`.

If you want to install the helm chart manually, you need to enable Istio's automatic sidecar injection:

```zsh
kubectl label namespace my-app istio-injection=enabled
```

To install a helm chart, you can run:

```zsh
helm install myapp ./helm/myapp-chart
```

To see all helm charts run the following:

```zsh
helm list
```

To switch between charts run:

```zsh
helm status <chart-name>
```

If you're running it for the first time, the model-service will download the models to cache them locally.
It takes a while so you can go grab a cup of coffee or something... :coffee:

The next invocations should be faster though.

Unfortunately, all the scripts are bash scripts so you will have to run them in bash (or z shell).
If you're using Windows, you can still download and use bash (maybe try using git bash).
If you're stuck with Powershell... helaas pindakaas...

## Monitoring

### Prometheus

To access Prometheus UI and Query metrics you can port forward from a new terminal in `./operation`:

```zsh
./scripts/update-hosts.sh
kubectl port-forward -n monitoring svc/myprom-kube-prometheus-sta-prometheus 9090
```

Then go to [http://localhost:9090](http://localhost:9090).
It is possible to query:

### Available Metrics

| Metric Name                                 | Description                                            | Labels                                              |
| ------------------------------------------- | ------------------------------------------------------ | --------------------------------------------------- |
| `frontend_prediction_requests_total`        | Total number of prediction requests sent from frontend | `status` (e.g. `200`, `500`)                        |
| `frontend_active_users_total`               | Current number of active users                         | `device_type` (e.g. `desktop`, `mobile`)            |
| `frontend_predict_request_duration_seconds` | Histogram of latencies for `/api/predict` requests     | —                                                   |
| `frontend_feedback_rating_total`            | Number of feedback ratings classified by type          | `feedback_type` (`positive`, `negative`, `unknown`) |

The metrics are also accessible at [http://app.local/metrics](http://app.local/metrics).

### Alerts

PrometheusRule - "HighFrontendRequestRate" exists and you can check that it can be triggered in Prometheus UI [http://localhost:9090](http://localhost:9090).
The alert notification functionality is still under development.

# Grafana Dashboard: Custom Metrics Visualization

To access the dashboard go to: Grafana URL: http://grafana.local/ (Credentials: admin / admin). After you ran the steps from [the setup](#How-to-run?)

The dashboard is automatically installed in Grafana using a Kubernetes ConfigMap and Helm chart. No manual import is required.

How it works:

- The dashboard JSON is stored at `operation/helm/myapp-chart/grafana/grafana-dashboard.json`.
- The Helm chart includes a ConfigMap (`templates/grafana/configMap.yml`) that mounts this dashboard into the Grafana pod.
- The deployment mounts the ConfigMap and uses a provisioning config (`provisioning-configMap.yml`) so Grafana loads dashboards from the correct path.
- When you deploy the Helm chart (e.g., with `./scripts/run-all.sh`), the dashboard appears automatically in Grafana.

### Updating the dashboard

To update the Grafana dashboard, replace the JSON file at `operation/helm/myapp-chart/grafana/grafana-dashboard.json` with your new or modified dashboard JSON. You can find dashboards on the [Grafana Dashboard Marketplace](https://grafana.com/grafana/dashboards/) or create your own using [these instructions](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/). After updating the JSON, redeploy the Helm chart to apply changes. You can use default Prometheus metrics or the [custom metrics listed above](#available-metrics).

---

# Particulars

## Docker Compose setup

This project is managed from the `operation/` directory using Docker Compose. It orchestrates multiple services across repositories.

## Running in Production using Docker compose

To run the application using prebuilt images (from GitHub Container Registry):

```zsh
cd operation
docker compose -f docker-compose.yml up -d
```

This uses `docker-compose.yml` only and does not mount local code.

The application should be accessible at [http://localhost:8080](http://localhost:8080)

## Provisioning Setup

> Note: We assume you have set up your SSH correctly, if not, please refer to the README in the `provisioning/` [here](https://github.com/remla25-team15/operation/tree/main/provisioning).

You can set up the VMs and provision them using the `scripts/run-provisioning.sh` script.

```zsh
./scripts/run-provisioning.sh
```

This script runs all necessary vagrant commands and then proceeds to provision the VMs.

After provisioning is successful, you need to add the kubernetes dashboard IP to your `/etc/hosts` so we can access it locally.
To do this, you can run:

```zsh
./scripts/update-hosts.sh
```

The Dashboard will then be accessible at: [https://dashboard.local/](https://dashboard.local/)

To access the Dashboard, you need a bearer token. You can generate it by running the following command:

```zsh
kubectl -n kubernetes-dashboard create token admin-user
```

> If you see errors regarding `kubectl`, please make sure you've set the KUBECONFIG variable correctly. (See README in `provisioning/`)

Copy and paste this token to access the dashboard.

#### More info:

Provisioning is done through the `/provisioning/` folder. The
corresponding README can be found [here](https://github.com/remla25-team15/operation/tree/main/provisioning)

> Note: To do provisioning manually, please make sure you `cd` into `provisioning/` folder

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
