## 1) REST API
The API has been developed in Python Flask. It fetches weather data from [api.open-meteo.com](https://api.open-meteo.com) and has two endpoints.
1) /api/hello, which returns weather data in your desired format if the request is successful. If any error occurs, it sends the following json.
```
{
  "datetime": "<datetime>",
  "error_message": "<error_message>",
  "hostname": "<hostname>",
  "version":"<api_version>"
}
```
2) /api/health, it tests third-party API reachability; the response format is below.
```
{
  "datetime": "<datetime>",
  "thirdPartyApiReach": "true|false",
  "hostname": "<hostname>",
  "version":"<api_version>"
}
```
## 2) Containerization
### 2.1, 2.2) Dockerfile
I maintained the following practices while containerizing the application. 
1) Select a very lighweight base image
2) Avoide installing unnecessary software and tools.
3) Minimize layers.
4) Expose only the port that is required.

<br/>The docker image is only 70.4MB in size. It is available in my public repository [hub.docker.com/repository/docker/shafatjamil/wxapi](https://hub.docker.com/repository/docker/shafatjamil/wxapi/general).<br/>

### 2.3) Docker Compose
I have created a Docker Compose file to deploy the API. I have mapped local port 80 to container port 5000. If port 80 is already in use, use a different port in the docker-compose.yml. Run the following command.
```
docker compose up -d
```

## 3) Version Control and CI/CD
### 3.1) Public Repository
I have created a public repository [github.com/safatjamil/Bs23](https://github.com/safatjamil/Bs23) and there is a GitHub Actions workflow. This workflow is triggered whenever a new release is created. You can check recent workflow runs in this tab [github.com/safatjamil/Bs23/actions](https://github.com/safatjamil/Bs23/actions).
```
name: Build and Publish the Docker Image
run-name: Version ${{ github.event.release.tag_name }} Build and Deploy
on: 
  release:
    types: [published]
```

### 3.2) Tag Docker Image
```
jobs:
  build_publish:
    runs-on: ubuntu-latest
    env:
      VERSION: ${{ github.event.release.tag_name }}
      DOCKER_USERNAME: shafatjamil
      LOCAL_TAG_NAME: wxapi
      REMOTE_REPO: shafatjamil/wxapi
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build
        run: |
          cd api
          docker build -t ${{ env.LOCAL_TAG_NAME }}:${{ env.VERSION }} .
      - name: Publish
        run: |
          docker login -u ${{ env.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_HUB_PAT }}
          docker tag ${{ env.LOCAL_TAG_NAME }}:${{ env.VERSION }} ${{ env.REMOTE_REPO }}:${{ env.VERSION }}
          docker push ${{ env.REMOTE_REPO }}:${{ env.VERSION }}
```
It fetches the release version and puts it in an environment variable 'VERSION'.

### 3.3) Version Consistency
The API reads version information from the 'version.yaml' file. Before a release, changing apiVersion in version.yaml to the release version will ensure consistency.

### 3.4) Deployment
I believe this requirement is ambiguous, as you did not mention where to deploy this application. However, I will discuss some scenarios.
1) Let's consider it is deployed as a deployment object in a Kubernetes cluster. I will run multiple pods from the beginning and perform a rolling update which gradually replaces the old pods with new ones.
2) If the application is deployed in Amazon ECS, I will set deployment type as rolling update and value of 'minimumHealthyPercent' will be set to a value that runs at least one old task while updating.
3) If the application is deployed in an Auto Scaling group, I will set the 'Replacement behavior' to 'Launch before terminating' . That will create new instances with this application before deleting the old one.

## 4) Terraform and Kubernetes

### 4.1, 4.2) Terraform Code and Modularity
The module is in the 'modules' directory. All resource definitions are in the 'main.tf' file. I have created one environment that is 'dev'. 'config.yaml' is the configuration file, and it has all the values that will be passed to the module. Please note that I have left some parameters blank so this will not run in the first attempt. Please add parameter values in backend.tf and adjust in other places to run.
<br/>Run the following command.<br/>
```
cd dev
terraform init
terraform plan
terraform apply
```

### 4.3) API credentials
The third-party API that I used didn't require an API key or token. However, I will show you how to store keys in secrets and use that in a pod.
Store the API key as a secret.
```
apiVersion: v1
kind: Secret
metadata:
  name: wx-third-party-api-key
data:
  api-key: <api_key>
```
To use this in a pod, mount this secret as an environment variable. This is a partial resource definition; to see the full definition, see manifests/deployment.yaml file.
```
spec:
      restartPolicy: Always
      containers:
      - name: wx-api
        image: shafatjamil/wxapi:1.0.0
        imagePullPolicy: IfNotPresent
        ports:
          - containerPort: 5000
        env:
          - name: API_KEY
            valueFrom:
              secretKeyRef:
                name: wx-third-party-api-key
                key: api-key
```
Run the following command to create a Kubernetes object.
```
kubectl apply -f manifest_file.yaml
```
### 4.4) Kubernetes Manifests
I have left some fields blank; please adjust that. I have left some fields blank; please adjust that. I am using the service mesh Istio as a network ingress.
1) Deployment: To run the pods, I have defined a deployment(deployment.yaml) object.
2) Service: For exposing the API, I have created a service(service.yaml) object.
3) Gateway: To create a load balancer at the front of the cluster, I have created an Istio gateway. It listens to three hosts. Actually, I have used this gateway for Grafana and Zipkin; however, forget that as of now. It listens to wx-api.brainstation-23.com and passes it to the VirtualService. Please create the TLS object for the HTTPS connection and route wx-api.brainstation-23.com subdomain to this gateway (load balancer). In AWS, create a record and route to the CNAME of this gateway (load balancer).
4) VirtualService: It contains the routing rules. It listens for the /api endpoint and forwards to the service (step 2).

### 4.5) Directories
Kubernetes manifests are in the 'manifests' directory, and Terraform code in the 'terraform' directory.

### 4.6) CI/CD Pipeline
I will use Jenkins this time for the CI/CD Pipeline. Please ensure that the Kubernetes cluster is accessible through the Jenkins instance using kubectl. Install Docker plugin in Jenkins.
1) Add a GitHub webhook and set your desired events (PULL_REQUEST_CREATED, PUSH, RELEASED).
2) Jenkins pulls GitHub code whenever the events occur. 
3) Build the Docker image.
4) Test the endpoints.
5) Push it to a private repository.
6) Run kubectl command to deploy to the cluster.
   
### 4.7) Observability
1) Metrics
<br/>For metrics collection, I have used kube-state-metrics. It collects metrics of Kubernetes objects. It has been used in conjunction with Prometheus and Grafana. Prometheus scrapes the metrics, and Grafana for visualization. Grafana uses the same gateway as the application in step 4.4.<br/>
[Reference] [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)

2) Logging
<br/>For log shipping, I have used Fluent Bit. Logs are stored in /var/log/containers. Fluent Bit runs as a DaemonSet in each node that ships the logs to an external Elasticsearch host.<br/>

3) Tracing
<br/>Zipkin is a distributed tracing system. I have added the manifest files; however, I have not added code in the API for instrumentation. I have tested in a Docker environment only, and Kubernetes Service DNS is different from Docker.<br/>




