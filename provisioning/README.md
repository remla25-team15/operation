## Creating and registering ssh keys

We would like to make connecting via SSH to the VMs more convenient by registering our public SSH keys so that
login does not require a password.

To generate an ssh key pair run the following command:

```zsh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible-provision-key -C "ansible provision key"
```

> Note: The name of the private key should remain unchanged as the inventory config assumes that
> `~/.ssh/ansible-provision-key` exists after you generate the keys using the given command

Move your public key to `public_keys/` folder and rename it to your name by running the following:

> Note: this command assumes that your current working directory is the `provisioning/` directory

```zsh
mv ~/.ssh/ansible-provision-key.pub public_keys/<your-name>-provision-key.pub
```

Add the `<your-name>-provision-key.pub` to the `Set up multiple authorized keys` task in general.yml file.

## Running the VMs

> You should register your SSH keys before trying to run the VMs

Simply run the following commands to manage the VMs:

To start the VMs, run:

```zsh
vagrant up
```

To destroy the VMs and remove all associated resources, run:

```zsh
vagrant destroy
```

To provision the VMs (e.g., apply configuration changes), run:

```zsh
vagrant provision
```

For pausing/resuming a VM use :

```zsh
vagrant suspend / vagrant resume
```

> Make sure you have registered your SSH keys before you can test the VMs.

You can test if your SSH keys are registered successfully by running

```zsh
ansible all -m ping
```

All services should return a response that looks like this:

```zsh
❯ ansible all -m ping
192.168.56.99 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.56.101 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.56.102 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

If you want to SSH into a VM, you can do it by running the command:

```zsh
ssh -i ~/.ssh/ansible-provision-key vagrant@192.168.56.<HOST>
```

> Replace `<HOST>` with the actual host you want to SSH into, e.g. 99 for ctrl.

## Accessing the Kubernetes Cluster from the Host

> `ctrl.yml` is initially provisioned during `vagrant up` so you don't need to rerun it unless
> you want to explicitly run it again.

1. Set up the kubernetes controller inside the VM environment.

```zsh
ansible-playbook -i inventory.cfg ctrl.yml
```

2. To manage your kubernetes cluster from the host machine you need to have an environment variable `KUBECONFIG` that points to this file
   for kubectl to use

```zsh
 export KUBECONFIG=$(pwd)/kubeconfig
```

3. Test access

- Check if the controller exists and is ready

```zsh
kubectl get nodes
```

- Check if the pod flannel got created

```zsh
kubectl get pods -A
```

## Finalizing the cluster

Run the finalization playbook with:

```
ansible-playbook finalization.yml
```

Then check if the namespaced CRDs, individually run:

```
kubectl get ipaddresspools.metallb.io -n metallb-system
kubectl get l2advertisements.metallb.io -n metallb-system
kubectl -n ingress-nginx get svc
kubectl -n kubernetes-dashboard get deploy
kubectl -n kubernetes-dashboard get ingress
```

For e.g. you should see something like this for all services:

```zsh
❯ kubectl -n kubernetes-dashboard get deploy

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
dashboard-metrics-scraper   1/1     1            1           155m
kubernetes-dashboard        1/1     1            1           155m
```

### Kubernetes dashboard

> You do not need to visit any external links — this section simply references the documentation that was used as a source. You may skip to the next section.

> To deploy the Kubernetes Dashboard, the following documentation has been consulted:
> [Deploying the Dashboard UI](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui)

> To access the Kubernetes Dashboard, you need a bearer token. The recommended way to generate it is by following the approach provided in the Kubernetes Dashboard GitHub documentation.
> [Creating a Sample User](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)

#### Enabling Direct access to the dashboard

1. Grab the external IP that MetalLB assigned to your ingress-nginx controller:

```zsh
export DASHBOARD_IP=$(
  kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
)
```

2. Append the mapping to /etc/hosts so dashboard.local resolves to that IP:
   > You might not need to run this again if you have already done so

```zsh
sudo sh -c "echo \"${DASHBOARD_IP} dashboard.local\" >> /etc/hosts"
```

3. Verify with:

```zsh
grep dashboard.local /etc/hosts
```

You should see a DNS entry like:

```zsh
❯ grep dashboard.local /etc/hosts
192.168.56.80 dashboard.local
```

The Dashboard will then be accessible at: [https://dashboard.local/](https://dashboard.local/)

> Note: We are using self-signed certificates so your browser will complain that your connection is not private,
> just trust us and proceed.

#### Enabling access to the dashboard via tunneling

If for some reason you cannot access the dashboard by following the above steps, you
can create a tunnel but we recommend setting up the direct access.

Run the following command to forward the Dashboard service to your local machine:

```zsh
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

The Dashboard will then be accessible at: [https://localhost:8443](https://localhost:8443)

#### Generating a Bearer Token

To access the Kubernetes Dashboard, you need a bearer token. You can generate it by running the following command:

```zsh
kubectl -n kubernetes-dashboard create token admin-user
```

Once the token is created, you can use it to log in to the Dashboard.

> The dashboard will show the default namespace, you can change the namespace to kubernetes-dashboard and
> look around to find the ingress service.
