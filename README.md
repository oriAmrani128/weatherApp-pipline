
# Weather App Jenkins Pipeline

This project involves setting up a Jenkins pipeline for automating the build, testing, and deployment of the Weather application. The pipeline includes stages for code quality analysis, Docker image creation, and deployment on an EC2 instance, with Slack notifications integrated for build status updates.

## Table of Contents
- [Overview](#overview)
- [Pipeline Stages](#pipeline-stages)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [How to Use](#how-to-use)
- [Resources](#resources)

## Overview

The Jenkins pipeline is designed to:
1. Fetch the Weather app code from a GitLab repository.
2. Run static analysis on the code.
3. Build and test a Docker image for the application.
4. Push the Docker image to DockerHub.
5. Deploy the app to an EC2 instance if all tests pass.
6. Notify relevant Slack channels about the success or failure of each build.

## Pipeline Stages

### 1. Static Analysis
   Running Pylint to ensure the code meets quality standards. Requires a Pylint score higher than 5 to proceed to the next stage.

### 2. Build and Test
   Builds a Docker image for the Weather app and starts the Docker container to test if the app is reachable.

### 3. Push to DockerHub
   If the tests pass, the Docker image is pushed to DockerHub for easy access.

### 4. Slack Integration
   Sends a Slack message to the "succeeded-build" channel if the build passes, and an error message to the "DevOps-alerts" channel if the build fails.

### 5. Deployment
   Deploys the updated container to an EC2 instance if the build succeeds.

## Prerequisites

- GitLab and Jenkins servers.
- Docker installed on the Jenkins server.
- Slack workspace and appropriate channel setup.
- AWS account and access to an EC2 instance.

## Setup Instructions

1. **Configure Jenkins**:
   - Install necessary Jenkins plugins (Git, Docker, Slack Notification).
   - Add credentials for DockerHub and GitLab in Jenkins.

2. **Pipeline Configuration**:
   - Copy the provided Jenkinsfile into your project repository.
   - Update any environment variables and credentials in the Jenkinsfile as required.

3. **Slack Integration**:
   - Set up a Slack webhook and configure the `slackSend` step in the Jenkinsfile to use the webhook URL and correct channel names.

4. **Deployment to EC2**:
   - Set up SSH access for Jenkins to the EC2 instance.
   - Ensure Docker is installed on the EC2 instance.

5. **GitLab Webhook Setup**:
   - In your GitLab repository, go to **Settings** > **Webhooks**.
   - In the **URL** field, enter the Jenkins webhook URL, e.g., `http://<jenkins_server>:<port>/project/<your_pipeline_name>`.
   - Under **Trigger** events, select **Push events** and **Merge requests**.
   - Add a secret token if desired for additional security.
   - Click **Add webhook** to save.

6. **Configure Jenkins to Trigger on Push**:
   - Ensure Jenkins has the GitLab plugin installed to handle webhook events.
   - In your Jenkins project configuration, set it to **Build when a change is pushed to GitLab**.
   - Filter the branch to only trigger builds when changes are pushed to `main`.

## How to Use

1. **Triggering the Pipeline Automatically**:
   - The Jenkins pipeline is set up to trigger automatically whenever code is merged into the `main` branch in the GitLab repository.
   - This is achieved by configuring a GitLab webhook to notify Jenkins of changes to the `main` branch.

2. **Monitoring the Pipeline**:
   - After the merge to `main`, Jenkins will automatically start the pipeline.
   - You can monitor the progress of each stage in the Jenkins console.

3. **Slack Notifications**:
   - Upon completion, the pipeline will send a notification to the designated Slack channels.
   - Successful builds will notify the `succeeded-build` channel, while failed builds will alert the `DevOps-alerts` channel.

4. **Accessing the Deployed Application**:
   - If the pipeline completes successfully, the updated application will be deployed on the EC2 instance.
   - Access the deployed application through the EC2 instance URL to confirm deployment success.

## Resources

- [GitLab Documentation](https://docs.gitlab.com)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com)
- [Slack API Documentation](https://api.slack.com/)
