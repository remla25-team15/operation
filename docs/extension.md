# Extension Proposal: Automated Model Re-training Based on User Feedback

> **Goal**  
> Replace today’s “train-once, deploy-forever” model with a **closed feedback loop** that turns daily user corrections into better models—safely, automatically, and on repeat.

---

## 1 Why We Need This Change

| Observed Shortcoming | Negative Effect in Production | Mitigation in This Proposal |
|----------------------|--------------------------------|-----------------------------|
| **Static model** trained only on the initial dump | Accuracy drifts as language and topics change | Continuous feedback ingestion + scheduled re-training |
| **Unused 👍/👎 feedback** | We lose ~ X high-quality labels per day | Store every vote, validate, add to training set |
| **Manual DVC trigger** | Slow, error-prone and costly interventions | One-click or cron-based Kubeflow pipeline |
| **No performance guardrails** | Risk of shipping worse models | Automated tests, drift checks, and canary release |

---

## 2 Solution Overview

![Continuous Learning Architecture](images/train_loop.webp)

*Figure 1 — Data flows from the user back to the model through Kafka, Kubeflow, and Istio.*

1. **Feedback Ingestion** – The frontend emits a *feedback* event for every prediction. We stream these events through Kafka, run schema checks, and store them in `postgres://feedback`.
2. **Data Curation** – A lightweight service scores, deduplicates, and tags new samples for re-training.
3. **Automated Re-training** – A Kubeflow pipeline (`/mlops/retraining/retrain-pipeline.yaml`) retrains the model nightly or on drift alerts from `drift_detector.py`.
4. **Validation & Safety Gates** – Unit tests, held-out metrics, and drift statistics must all beat the current production model before promotion.
5. **Progressive Delivery** – Istio DestinationRules expose the new image as a 10 % canary; Sticky Sessions ensure consistent user experience.
6. **Monitoring** – Grafana panels track accuracy, drift, deployment success, and feedback volume.

---

## 3 Portability & Broader Use

| Component | Restaurant Reviews (today) | E-commerce Ratings | Support Tickets |
|-----------|----------------------------|--------------------|-----------------|
| Event schema | `review_id`, `text`, `👍/👎` | `order_id`, `stars` | `ticket_id`, `resolution_yes/no` |
| Feature store | TF-IDF + fastText | Product metadata | BERT embeddings |
| Model head | Sentiment classifier | Rating predictor | Intent classifier |

Only the schema and training script swap out; Kafka topics, Kubeflow pipeline, and Istio rollout stay unchanged. Any team with user feedback can adopt the pattern.

---

## 4 Experiment Plan

| Parameter | Control | Treatment |
|-----------|---------|-----------|
| Model | Current static (v1) | Continuous-learning (v2) |
| Traffic share | 50 % | 50 % |
| Duration | 90 days |
| KPIs | Accuracy on feedback labels, feedback rate, manual interventions, deployment failures |
| Success | +10 % accuracy, +15 % feedback, −50 % manual work, ≤1 % failures (p < 0.05) |

Progress will be visible on a Grafana dashboard (`grafana-dashboard-continuous.json`). We annotate re-train events and canary start/stop to prove cause and effect.

---

## 5 Implementation Artefacts

| File / Resource | Purpose |
|-----------------|---------|
| `mlops/retraining/retrain-pipeline.yaml` | Defines the Kubeflow workflow (ingest → train → test → register) |
| `mlops/drift_detector.py` | Statistical drift monitor publishing Prometheus metrics |
| `helm/istio/continuous-canary.yaml` | Gateway, VirtualService, DestinationRule with 90/10 split & Sticky Sessions |
| `docs/images/continuous-learning-architecture.png` | Architecture diagram used above |
| `grafana/grafana-dashboard-continuous.json` | Importable dashboard |

---

## Related Work

### Industry Examples
| # | Project | Key Take-aways | Link |
|---|---------|---------------|------|
| 1 | **Continuous Training & Deployment in MLOps** | Shows how automation, monitoring, and feedback loops form the backbone of robust ML lifecycles. | [Medium](https://rihab-feki.medium.com/mlops-02-7-things-you-need-to-learn-about-continuous-training-continuous-deployment-f3ec31d969e3) |
| 2 | **Google TFX (TensorFlow Extended)** | Demonstrates a production pipeline that performs continuous training, validation, and safe rollout. | [Google AI Blog](https://ai.googleblog.com/2017/09/introducing-tfx-tensorflow-extended.html) |
| 3 | **Uber Michelangelo** | Describes an end-to-end platform with real-time feature serving and automatic model updates. | [Uber Engineering](https://eng.uber.com/michelangelo-machine-learning-platform/) |

### Open-Source Tools & Frameworks
| # | Tool | Why We Care | Link |
|---|------|-------------|------|
| 1 | **MLflow** | Provides experiment tracking and a model registry—ideal for storing and promoting re-trained models. | [Documentation](https://mlflow.org/docs/latest/index.html) |
| 2 | **Kubeflow** | Orchestrates Kubernetes-native pipelines; we use it for scheduled re-training and validation. | [Docs](https://www.kubeflow.org/docs/) |
| 3 | **Apache Kafka** | Enables real-time ingestion of user feedback and event-driven processing for our pipeline triggers. | [Streams Docs](https://kafka.apache.org/documentation/streams/) |

---

## 7 Conclusion

By closing the feedback loop we:

* **Stop accuracy drift** and learn from every new review.
* **Save engineering time** through hands-off re-training and deployment.
* **Create a reusable template** for any domain that collects user feedback.

This extension directly removes our biggest release-engineering pain point and positions the project for long-term, data-driven improvement.