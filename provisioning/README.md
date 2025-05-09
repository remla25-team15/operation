## Running the VMs

Simply run

```zsh
vagrant up
```

> You should register your SSH keys before trying to run the VMs

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

> Replace <HOST> with the actual host you want to SSH into, e.g. 100 for ctrl.
