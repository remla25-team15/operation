# Table of Contents

- [Use Case](#use-case)
  - [Overview](#overview)
  - [Screenshots](#screenshots)
- [Design Documentation](#design-documentation)
- [How to Run](#how-to-run)
  - [Manual Kubernetes Access](#manual-kubernetes-access)
  - [Helm Charts](#helm-charts)
- [Canary and Label-Based Routing with Istio](#canary-and-label-based-routing-with-istio)
  - [Frontend Canary Testing](#frontend-canary-testing)
  - [Backend Version Control](#backend-version-control)
  - [Sticky Sessions with `x-user` Header](#sticky-sessions-with-x-user-header)
- [Monitoring](#monitoring)
  - [Prometheus](#prometheus)
  - [Alerts](#alerts)
- [Grafana Dashboard](#grafana-dashboard)
- [Docker Compose Setup](#docker-compose-setup)
- [Provisioning Setup](#provisioning-setup)
- [Development](#development)
- [API Documentation](#api-documentation)

# Use Case: Restaurant Sentiment Analysis

![](docs/images/use-case.png)

Our application features a simple interface where users can enter text about a
restaurant experience to analyze its sentiment. As they type, text analysis
happens in real-time, showing the predicted sentiment instantly. This analysis
is done by a sentiment analysis model on the backend, which is handled by a
dedicated service. The user then sees whether the text is positive or negative,
and their feedback helps us analyze the performance of the model to
continuously improve it over time.

---

# Design Documentation

You can find our deployment documentation at [`docs/deployment.md`](docs/deployment.md).

Documentation for continuous experimentation is also located in [`docs/deployment.md`](docs/deployment.md).

The extension proposal is documented at [`docs/extension.md`](docs/extension.md).

---

# How to Run

> :warning: **SSH Setup Required:** Please generate and configure your SSH keys
> before attempting to provision. Instructions are available in the
> [`provisioning/`](https://github.com/remla25-team15/operation/tree/main/provisioning)
> README.

To provision, orchestrate, and deploy the application using Kubernetes:

```bash
./scripts/run-all.sh
```

The application will be accessible at [http://myapp.app.local/](http://myapp.app.local/).

The script will wait for pods and services to become available and is safe to re-run if it times out:

```bash
./scripts/run-all.sh --provision
```

Provisioning is mostly idempotent and will resume as needed. Models are
downloaded and cached in `provisioning/shared/`, improving subsequent runs.

> :coffee: First run may take a while. Grab a coffee!

If you're running it for the first time, the model-service will download the
models to cache them locally in a shared folder provisioning/shared/ which is
shared across all VMs and mounted in the container. This is persistent so
subsequent invocations will use this rather than downloading the model again
whenever the container is re-created.

> :warning: **DNS Entries:** Ensure your `/etc/hosts` contains entries like:
>
> ```
> 192.168.56.80 myapp.app.local kiali.local prometheus.local grafana.local
> 192.168.56.81 dashboard.local
> ```
>
> These should be added automatically by `scripts/update-hosts.sh`. If not, add them manually.

> :warning: Bash required: Scripts are written in Bash/Zsh. On Windows, use Git Bash.

---

## Manual Kubernetes Access

To manage Kubernetes from your host:

```bash
cd provisioning/
vagrant ssh ctrl -c "sudo cat /etc/kubernetes/admin.conf" > kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
cd ..
```

Run this command in each new shell session.

---

## Helm Charts

Enable Istio sidecar injection:

```bash
kubectl label ns default istio-injection=enabled
```

Install charts:

```bash
helm install monitoring ./helm/monitoring-chart
helm install myapp ./helm/app-chart
```

List and check chart status:

```bash
helm list
helm status <chart-name>
```

To test multiple releases, install another app instance and update `/etc/hosts` accordingly.

---

# Canary and Label-Based Routing with Istio

## Frontend Canary Testing

Users with header `user-group: canary` receive the v2 frontend (with thumbs). Others receive v1 (buttons).

### v2 (Canary)

```bash
curl -s -H "user-group: canary" app.local | grep -A18 "Prediction"
```

### v1 (Default)

```bash
curl -s app.local | grep -A5 "Prediction"
```

## Backend Version Control

Use `label` header to route to specific versions:

```bash
curl -H "label: v1" app.local/app/api/version
curl -H "label: v2" app.local/app/api/version
```

## Sticky Sessions with `x-user` Header

```bash
count=0; while [ $count -lt 8 ]; do
  curl -s -H "x-user: bob" http://app.local | grep -A5 "Prediction"
  ((count++))
done
```

---

# Monitoring

## Prometheus

To access Prometheus:

```bash
./scripts/update-hosts.sh
kubectl port-forward -n monitoring svc/myprom-kube-prometheus-sta-prometheus 9090
```

Then visit [http://localhost:9090](http://localhost:9090).

### Custom Metrics

| Metric Name                                 | Description               | Labels          |
| ------------------------------------------- | ------------------------- | --------------- |
| `frontend_prediction_requests_total`        | Total prediction requests | `status`        |
| `frontend_active_users_total`               | Active users              | `device_type`   |
| `frontend_predict_request_duration_seconds` | Request latency histogram | —               |
| `frontend_feedback_rating_total`            | Feedback count by type    | `feedback_type` |

Available at [http://app.local/metrics](http://app.local/metrics).

## Alerts

Custom PrometheusRule `TooManyActiveUsers` triggers at >15 users. To receive emails:

```bash
kubectl create secret generic alertmanager-smtp-secret \
  --from-literal=smtp_username=fake-user@example.com \
  --from-literal=smtp_password=fake-password \
  -n monitoring
```

Upgrade releases:

```bash
helm upgrade --install myapp helm/app-chart/ -f helm/app-chart/values.yaml
helm upgrade --install monitoring helm/monitoring-chart/ -f helm/monitoring-chart/values.yaml
helm upgrade --install myprom prometheus-community/kube-prometheus-stack -n monitoring -f helm/app-chart/values.yaml
kubectl delete pod -n monitoring alertmanager-myprom-kube-prometheus-sta-alertmanager-0
```

Check config:

```bash
kubectl exec -n monitoring -it alertmanager-myprom-kube-prometheus-sta-alertmanager-0 -- cat /etc/alertmanager/config_out/alertmanager.env.yaml
```

---

# Grafana Dashboard

Access: [http://grafana.local/](http://grafana.local/) (admin / admin)

Dashboard is deployed via ConfigMap and Helm. JSON config located at:

```
operation/helm/myapp-chart/grafana/grafana-dashboard.json
```

### Update Dashboard

Replace the JSON file and redeploy the chart:

- [Grafana Dashboard Marketplace](https://grafana.com/grafana/dashboards/)
- [Dashboard Docs](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/)

---

# Docker Compose Setup

From `operation/`:

```bash
cd operation
docker compose -f docker-compose.yml up -d
```

App will be available at [http://localhost:8080](http://localhost:8080).

---

# Provisioning Setup

> SSH must be correctly configured. See [`provisioning/`](https://github.com/remla25-team15/operation/tree/main/provisioning)

```bash
./scripts/run-provisioning.sh
./scripts/update-hosts.sh
```

Access dashboard at: [https://dashboard.local/](https://dashboard.local/)

Generate access token:

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

---

# Development

## API Documentation

Docs are available at:

- app-service: [http://myapp.app.local/app/apidocs/](http://myapp.app.local/app/apidocs/)
- model-service: [http://myapp.app.local/model/apidocs/](http://myapp.app.local/model/apidocs/)

### Expected Directory Structure

```
.
├── operation/
│   ├── docker-compose.yml
│   └── docker-compose.override.yml
├── app-frontend/
├── app-service/
├── lib-ml/
├── lib-version/
├── model-service/
└── model-training/
```

Clone:

```bash
./clone.sh
```

Run in development mode:

```bash
cd operation
docker compose up --build
```

Access: [http://localhost:8080](http://localhost:8080)

### Clean-up

```bash
docker compose down
docker compose logs -f
```

---
