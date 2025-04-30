# Restaurant Sentiment Analysis Using Machine Learning

## Overview
This project is a modular, containerized web application for classifying restaurant review sentiments.

Users can input a short review into a web UI, which is sent to the backend (app-service). The app-service preprocesses the review and forwards it to the model-service. The model predicts the sentiment (positive/negative), and the result is displayed in the frontend.

This application demonstrates best practices in versioning, containerization, modular ML architecture, and release engineering.

## Architecture

- **Frontend** (`app-frontend`) – to be announced
- **App Service** (`app-service`) – API gateway that communicates with the model and frontend
- **Model Service** (`model-service`) – Flask? API wrapping the trained ML model
- **Model Training** (`model-training`) – trains and exports a sentiment classifier model
- **Shared Libraries**:
  - `lib-ml`: Preprocessing (shared by training and inference)
  - `lib-version`: Holds and exposes version info
- **Orchestration** (`operation`): Docker Compose config + coordination

## Repositories
- [operation](https://github.com/remla25-team15/operation)
- [app-service](https://github.com/remla25-team15/app-service)
- [app-frontend](https://github.com/remla25-team15/app-frontend)
- [model-service](https://github.com/remla25-team15/model-service)
- [model-training](https://github.com/remla25-team15/model-training)
- [lib-ml](https://github.com/remla25-team15/lib-ml)
- [lib-version](https://github.com/remla25-team15/lib-version)

## Running the Application

> Docker Compose setup is coming soon in `docker-compose.yml`

## Assignment Progress Log

### A1: Versions, Releases, and Containerization
