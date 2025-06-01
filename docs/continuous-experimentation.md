# Continuous Experimentation

## Overview

This document describes the continuous experimentation process used to evaluate a new feature introduced in the frontend of our sentiment analysis web application. The goal is to determine whether the new feature improves user button usage.

## Experimental Feature

**Feature:** Feedback icons (👍 / 👎) are added instead of "Correct" and "Incorrect" buttons in the sentiment analysis web application.

**Feature Branch:** `experiment-feature-ui-icons`  
**Tag format:** `vX.Y.Z-feature-feedback-icons`

**Base Version (Control):** `main` branch  
**Tag format:** `vX.Y.Z`

The feature was deployed as a separate version of the front-end application, allowing us to compare user interaction rate between the base version and the experimental version in A/B testing. 

## Hypothesis

> **H_0 (Null Hypothesis):** The addition of feedback icons does not change the percentage of user feedback interactions per prediction request compared to the base version.
>
> **H_1 (Alternative Hypothesis):** The version with feedback icons will have a higher percentage of user feedback interactions per prediction request compared to the base version.

## Metrics

To falsify the hypothesis, look at following metrics scraped by Prometheus:

| Metric Name                     | Description                                             |
|---------------------------------|---------------------------------------------------------|
| `prediction_requests_total`     | Counter for prediction requests made by users           |
| `feedback_rating_total`         | Counter for feedback events (positive or negative)      |

## Deployment Setup

>TODO: How is the feature deployed \
>TODO: What is the split of traffic between the two versions
