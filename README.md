# Rearc Data Quest

## Overview
Here lies the implementation for the Rearc Data Quest Project. The instructions were simple, to fetch two different datasets on a daily basis (Extract), synchronize the datasets with data in S3, perform some tranformations on the data (Transform), and write three datasets to a results S3 Bucket. The result datasets are processed on an SQS Queue and their contents are then logged out.

## Goals
The goal of this project are to showcase my skills in data engineering by implementing a full end-to-end data pipeline, deployed in the cloud. 

## Architecture
The architecture for this project starts here in the Github Repository. Here is where we manage our source code, gate deploys with tests, and manage and deploy our Infrastructure as Code (Terraform). The terraform code for this project resides in the `cicd/terraform` folder and is seperated by AWS product.

### AWS Cloud Architecture
The AWS architecture is managed fully using Terraform. This involves an EventBridge Scheduler that calls a Step Function on a daily basis at 08:00. The Step Function while not required for the exercise is meant to show how this framework could be scaled to include more tasks in its data orchestration. For now, it has two steps. 

The first task is to invoke the Fetcher Lambda. The Fetcher downloads files from a Bureau of Labor Statistics repository and population data from a public API. These files are then synchronized with a raw data bucket in S3, only updating or adding files if necesary. The synchronization is performed by taking an MD5 hash of the fetched files and comparing them to the ETag of the files in S3 to verify if they have changed. Once the raw data files have been written to the raw data bucket, the next task in our Step Function is to perform transformations on the raw data to build the three required result datasets and writes them to our processed data bucket as JSON. At this point the batched processing nature of our architecture is complete and we move on to a more event based architecture. 

The event based architecture is performed by attaching an S3 Bucket notification to our processed data that publishes to an SQS Queue. Each file written to the processed data bucket gets one message on the queue and its message on the queue triggers one invocation of the Logger Lambda. The Logger Lambda consumes the SQS Message containing S3 details about the file, reads in the file and logs out the data to CloudWatch.

![AWS Cloud Architecure](./Rearc%20Data%20Quest%20Architecture.png)

#### Github Actions Architecture
Our Github actions are designed to be a simple representation of how a production project might look and run. It involves gating releases based on conditions, in this case being the passing of unit tests. Our actions pipeline also handles the deployment of Terraform for our AWS Architecture. On pull requests a "plan only" run is triggered via Hashicorp's API. On commits to `main` a Terraform "plan and apply" is triggered via Hashicorps API that requires manually running apply to actually create, destroy, or update our AWS architecture. Feel free to view the YAML files in .github/workflows to see how this works.

## Testing
This project uses automated testing ran via GitHub Actions that gates deploys and informs creators of pull requests if their changes violate any test conditions. Ordinarily, I would strive for near 100% test coverage but in the interest of time I have decided to leave it out. I have included basic test stubs and included them in the Github Actions pipeline to display how they would work if implemented.

#### Testing Scala Spark Job
*NOTE: Scala and Spark must be preinstalled*
Tests are ran by starting in the `rearc-spark` directory and running `sbt test`

#### Testing Python Lambdas
*NOTE: Python 3.13 must be installed, as well as any dependencies mention in requirements.txt*
Start in the `lambdas` folder and run `pytest`

## Future Enhancements 
While I know this is just a project to show off my skills, I would like to note that due to constraints on time there are missing features that I believe would be necessary for a true Production Grade project. The first and probably most important to me is the lack of test coverage. The code in this project could be easily broken down into smaller functions which would allow for testing each part in a logical way, achieving near 100% test coverage. I would then use this test coverage score to gate merging of pull requests on a condition that they satisfy a certain test coverage percentage. The next feature would be more configurability overall. Some examples being, the Lambdas currently do not use their event variables but they could be altered to allow the ability to pass different search filters to the Fetcher Lambda or change the delivery method of the the Logger Lambda uses to display its results. 
