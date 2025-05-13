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

> TODO: glob all .pub files in `public_keys/` to remove this step.

You can test if the keys are registered successfully by running

```zsh
ansible all -m ping
```

All services should return a response that looks like this:

```zsh
❯ ansible all -m ping
192.168.56.100 | SUCCESS => {
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

> Replace <HOST> with the actual host you want to SSH into, e.g. 99 for ctrl.

## Accessing the Kubernetes Cluster from the Host

> We provision everything in the Vagrantfile

TODO: Improve this block to only explain what is needed to be done because we don't need to additionally
provision anything.

> First step is not necessary as the `ctrl.yml` is executed during `vagrant up`.

Set up the kubernetes controller inside the VM environment.

```zsh
ansible-playbook -i inventory.cfg ctrl.yml
```

TODO: The preceeding block can be removed

To manage your kubernetes cluster from the host machine copy the kubeconfig file from the controller VM
and export it for kubectl to use

```zsh
 vagrant ssh ctrl -c "sudo cat /etc/kubernetes/admin.conf" > kubeconfig
```

```zsh
export KUBECONFIG=$(pwd)/kubeconfig
```

Test access

Check if the controller exists and is ready

```zsh
kubectl get nodes
```

check if the pod flannel got created

```zsh
kubectl get pods -A
```

## finalizing the cluster

> TODO: Is this necessary? -> we can't run the playbook with `ansible-playbook -u vagrant -i 192.168.56.100, finalization.yml` because..

> We run the provisioning in vagrantfile, so no need to do this either.
> Run the finalization notebook with:

```
ansible-playbook -u vagrant -i inventory.cfg finalization.yml
```

TODO: Preceeding block can be removed.

Then check if the namespaced CRDs run:

```
kubectl get ipaddresspools.metallb.io -n metallb-system
kubectl get l2advertisements.metallb.io -n metallb-system
kubectl -n ingress-nginx get svc
kubectl -n kubernetes-dashboard get deploy
kubectl -n kubernetes-dashboard get ingress
```

### Kubernetes dashboard documentation

You do not need to visit any external links — this section simply references the documentation that was used as a source. You may skip to the next skip.

To deploy the Kubernetes Dashboard, the following documentation has been consulted:
[Deploying the Dashboard UI](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui)

To access the Kubernetes Dashboard, you need a bearer token. The recommended way to generate it is by following the approach provided in the Kubernetes Dashboard GitHub documentation.
[Creating a Sample User](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)

#### Generating a Bearer Token

To access the Kubernetes Dashboard, you need a bearer token. You can generate it by running the following command:

```zsh
kubectl -n kubernetes-dashboard create token admin-user
```

Once the token is created, you can use it to log in to the Dashboard.

#### Enabling Access to the Dashboard

1. Grab the external IP that MetalLB assigned to your ingress-nginx controller:

```
export DASHBOARD_IP=$(
  kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
)
```

2. Append the mapping to /etc/hosts so dashboard.local resolves to that IP:

```
sudo sh -c "echo \"${DASHBOARD_IP} dashboard.local\" >> /etc/hosts"
```

3. Verify with: `grep dashboard.local /etc/hosts`

> OR Run the following command to forward the Dashboard service to your local machine:

```zsh
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

The Dashboard will then be accessible at: [https://localhost:8443](https://localhost:8443)
