from diagrams import Cluster, Diagram
from diagrams.k8s.compute import Pod
from diagrams.custom import Custom
from urllib.request import urlretrieve
from diagrams.gcp.network import LoadBalancing
from diagrams.gcp.compute import KubernetesEngine
from diagrams.onprem.client import User

with Diagram("Load testing environment", filename="diagram", show=False, direction="LR"):
    # outformat="svg", 
    # download the icon image file
    terraform_url = "https://github.com/mingrammer/diagrams/raw/master/resources/onprem/iac/terraform.png"
    terraform_icon = "terraform.png"
    urlretrieve(terraform_url, terraform_icon)

    terraform = Custom("Terraform", terraform_icon)

    with Cluster("GKE Cluster"):
        with Cluster("Locust Cluster"):
            workers = [
                Pod("Locust worker"),
                Pod("Locust worker"),
                Pod("Locust worker")]
            master = Pod("Locust master")
            master - workers
        
        lb = LoadBalancing("LB")
        cluster = lb >> master

    terraform >> lb
    User("Tester (Access via glcoud command)") >> lb
    workers >> KubernetesEngine("A Target Site")