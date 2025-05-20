# using mingrammer: https://diagrams.mingrammer.com/
# Pre-requisites:
# pip install diagrams
from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.database import MariaDB
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Apache
from diagrams.onprem.iac import Ansible

with Diagram("Ansible lab architecture", show=True, direction="TB"):
    orchestrator = Ansible("Ansible orchestrator")

    with Cluster("demo"):
        grpdemo = [
            Server("sshnode")]

    with Cluster("barcelona"):
        grpbcn = [
            Apache("web1")]

    with Cluster("tokyo"):
        grphnd = [
            Apache("web2"),
            Apache("web3")]

    with Cluster("db"):
        grpdb = [
            MariaDB("mariadb1")]

    orchestrator >> grpdemo
    orchestrator >> grpbcn
    orchestrator >> grphnd
    orchestrator >> grpdb

    # Ansible("Ansible orchestrator") >> [
    #     Server("sshnode"),
    #     Apache("web1"),
    #     Apache("web2"),
    #     Apache("web3"),
    #     MariaDB("mariadb1")]

# diagrams.onprem.database.Mariadb, MariaDB
# diagrams.onprem.database.Mysql, MySQL