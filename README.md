# Locust Load Testing
This repository is for setting up load testing environment on GKE with terraform.

![diagram](docs/diagram.png?raw=true "Diagram")
# Pre Request
- gcloud >= Google Cloud SDK 349.0.0
- kubernetes-cli >= 1.22.1
- terraform >= 1.0.5
- python >= 3.9 (To generate diagram)
# How to Set Up on GKE
## Configure Makefile
Copy `Makefile.example` and fill out attributes below:
| value | description |
|:-- |:--|
| PROJECT_ID | GCP Project ID |
| CLUSTER_NAME | Cluster base name. Due to the cluster deletion takes time, this tool add a random texts at the end of the base cluster name |
| REGION | GCP Region name |
| ZONE | GCP Zone name |
| MACHINE_TYPE | Machine type of loading machines. Please see [machine types](https://cloud.google.com/compute/docs/general-purpose-machines) for more details |
| CREDENTIALS | The full path to the Service Account JSON file. |
| SERVICE_ACCOUNT_EMAIL | Service Account Email. Eg. `[User name]@[Project name].iam.gserviceaccount.com` |
| TARGET_HOST | Target host URL |

## Set Up Google Kubernetes Cluster (GKE)
1. Navigate to `deploy` folder.
 
    ```
    make init_all
    ```
     to set up `terraform`
1. Run 
    ```
    make build
    ```
    to set up a GKE cluster and initialize and `gcloud` command pointing to the created GKE cluster.
1. Run 
    ```
    make a_locust
    ```
    to set up `locust` and required config maps (storing load test scripts) for performance testing.
1. Run
    ```
    make locust
    ```
    This will do port forwarding to the local. Then you can access to `Locust Master` with `localhost:8089`.
1. Stop `make locust` and Run
    ```
    make refresh
    ```
    This will refresh the Locust Cluster with updated `main.py` script file and `values.yaml` content. Once the Locust Cluster up and running, connect the master with `make locust`
## Tear Down GKE Cluster
Run
```
make d_all
```

## Update Code for Load Testing
At each load testing scripts update, workers need to be redeployed to read the latest config maps where testing scripts are stored according to the Kubernetes specification. This way allows you to update with one command.

1. If you are already connecting the load cluster with `make locust`, Ctrl+C to stop it.
1. All code is stored under `locust` directory. `main.py` is the main logic, and libraries are under the `lib` directory.
1. Once code is updated, run
    ```
    make refresh
    ```
    to reload `ConfigMap` and Locust clusters to read the updated config map.
1. Run `make locust` again to connect the load cluster.

## How to Adjust Balance of Workers and Users
To generate the load at a lower cost, you may want to use as few workers as possible. This is a sample step on how to adjust the number of users and workers appropriately.

In the case of generating 10000 RPS, here are the steps that I tried.

1. Enable HPA, start from 10 workers with 2000 users, and see how much load the Locust cluster can generate. In this case, Locust generated 3000 RPS and saturated there. No CPU errors are observed in Cloud Logging, which implies CPU is still not pushed to the limit. 
1. Assuming 3 times more users would generate 10000 RPS. Change users to 6000 and run `make refresh` to restore `ConfigMap` and Locust pods.
1. You observed workers automatically scaled to 15 and the load reached higher than 10000 RPS. 
1. Adjust the initial worker to `15` in the `values.yaml` and `make refresh` to update the Locust pods.

## Reference Settings
In the case where you use `spike_load.py` to generate **10000RPS** with the Locust Cluster on GKE, here is the reference configuration.

`spike_load.py` hatches users at once and hold requests until all users are spawned **in each worker** (not across all workers).

| parameters | description |
|:-- | :-- |
| Machine type of locust worker (`MACHINE_TYPE` in `Makefile`) | e2-standard-2 |
| Replicas for worker (line 66 of `values.yaml`) | 15 |
| User amount (line 15 of `spike_load.ph`, `user_amount`) | 10000 |

With this settings,
- The first second RPS is around 600
- It'll reach 10000RPS in 15 to 20 seconds, and go higher. You may want to pace the access with `constant_pacing` function if you exactly target 10000RPS and dwell (stay) for a while.

In `spike_load.py`, the below line configure the dwell load time. This code means dwell 120 seconds with amount of user_amount users. Adust dwell time accordingly.
```spike_load.py
 targets_with_times = Step(user_amount, 120)
```

# How to Run Locally
You may want to iterate try and error quickly while building a testing script. Loading the testing script every time on GKE is quite troublesome. For the development phase, you can leverage Docker to run a small cluster locally.

Spin up the small locust cluster, run
```
docker-compose up --build --scale worker=1
```
and you can access to the master from `localhost:8089`

# Tips

## Test Script Locally first and move on the production.

Locust stops with exceptions when syntax errors are included in the loading script. For a faster turnaround, you may want to make sure the script works correctly at the local first and move on to the production.
## Help of Commands
Run `make help`
## How to Access Locust Master Manually
1. Go to GCP console > `Services & Ingress`
1. Open `locust-cluster`, scroll down to `Ports`
1. Click `PORT FORWARDING` button of `master-p3`, with port `8089` row
1. A dialog will be popped up and displays the port forwarding code in there. Copy & Paste onto the terminal, and run.
1. You can access the `locust-cluster` master pod with `localhost:8080` from your browser.
## How to Configure gcloud for The GKE Cluster by Default
This can be done just run `make build`, but also separately as below:
1. Build cluster with 
    ```
    make build_cluster
    ```

1. Run 
    ```
    make gcloud_init
    ```
    This command will configure your `gcloud` environment pointing to the newly created GKE cluster.
## How to Generate Diagram
1. Install `Diagrams` following [this step](https://diagrams.mingrammer.com/docs/getting-started/installation).
1. Go to `docs` directory and run `python diagram.py`

## How to Enable Autoscaling
Autoscaling is depending on Kubernetes's [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#how-does-the-horizontal-pod-autoscaler-work)(HPA). To enable HPA, Kubernetes manifest needs to include `resource` to sepecify the pod's resource allocation so that Kubernetes can manage the pods based on the CPU usage.