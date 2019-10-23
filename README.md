# ProjectName Infrastructure

This repository controls the names and configurations of the ProjectName
servers hosted on DigitalOcean.

## How it works

### 1. Create servers

This part of the process uses
[terraform](https://www.terraform.io/)
to create new droplets (servers) on DigitalOcean.

The following steps need to be done once per computer:

- [Install terraform](https://www.terraform.io/downloads.html)
  on your local machine.  It is just a single executable file that you can put
  anywhere in your `$PATH` directory.  **Note** we are not using the latest
  version of Terraform, see the "Compatibility" section below for details!

- Add some **public SSH keys** (including your own) to a file named
  `keys/ssh_authorized_keys_ROOT.txt` under this directory.  There should be
  one key for each member of the infrastructure team; ask someone if you don't
  have them or you aren't sure what this file should look like.  These are the
  keys that will be added to any new servers you create.

- Grab a Cloudflare API key from
  [your profile page](https://dash.cloudflare.com/profile)
  and create a file in this directory named `cloudflare.tf`:

```
provider "cloudflare" {
    email = "you@example.com"
    token = "your-api-key"
    version = "~> 1.12"
}
```

- Grab a DigitalOcean API key from
  [the Applications & API page](https://cloud.digitalocean.com/account/api/tokens)
  and create a file in this directory named `digitalocean.tf`:

```
provider "digitalocean" {
    token = "your-api-key"
    version = "~> 1.9"
}
```

- Get a copy of the latest `terraform.tfstate` file from someone on the
  infrastructure team.

- Change to this directory and run `terraform init`.

- Verify that Terraform would not make any changes to the current state by
  running `terraform plan`.  The result of this command should be **No changes.
  Infrastructure is up-to-date.**  If you see otherwise, it probably means you
  have an **outdated state file** and you need to **contact someone on the
  infrastructure team** before making any changes.

#### To add a new server

- Add a new `module "projectname_SERVERNAME"` block to `projectname.tf`
  (note, using an underscore instead of a dot here because Terraform module
  names don't allow dots)
- Run `terraform get` to refresh the module structure
- Run `terraform plan` and inspect the execution plan
- † If everything looks ok, run `terraform apply`

† **Be very careful that no existing servers** ("resources" in Terraform
terminology) **will be deleted by your execution plan.**  With the way our
servers are currently set up, this **will** cause data loss!

If you see `(new resource required)` or `(forces new resource)` in the output
of `terraform plan` or `terraform apply`, **STOP**, press `Ctrl+C` to abort
what you were doing, and ask for help!

#### Compatibility

This process has been tested with the following `terraform` and plugin
versions:

```
$ terraform --version
Terraform v0.11.14
+ provider.cloudflare v1.12.0
+ provider.digitalocean v1.9.1
+ provider.template v2.1.0
```

In particular `terraform` 0.12 is a major upgrade, and our configuration files
will need some re-working before we can change to that version.

### 2. Configure servers

This part of the process uses
[ansible](https://www.ansible.com/)
to configure existing servers and change their configuration.

In addition to completing the `terraform` installation steps from above, you'll
need to have `pip` and `virtualenv` installed.  Here is a general
[guide](https://packaging.python.org/guides/installing-using-pip-and-virtualenv/)
to installing `pip` (a Python package manager) and using it to install
`virtualenv`.

Once you're in the directory for this repository, run the commands to
initialize and activate a Python virtual environment:

```sh
virtualenv .
. bin/activate
pip install
```

`virtualenv .` and `pip install` only need to be run once per computer, and `.
bin/activate` needs to be run with every new shell session where you're using
this directory.

#### To update the configuration of existing servers

Run `scripts/run-ansible-playbooks.sh`.

Currently this will update all the Devuan servers as follows:

- `apt-get update` and `apt-get upgrade`
- Install some additional packages common to all servers (usually these are
  packages that were added after the initial server configuration was written)

## Helper scripts

### `scripts/find-ssh-key.sh`

After you have set up a `keys/ssh_authorized_keys_ROOT.txt` file with the
public keys of the infrastructure team, this script will look at the keys
loaded in your `ssh-agent` and find the one that matches.

If it's not working, run `ssh-add ~/.ssh/my-projectname-key` and type the
passphrase for your key.

### `scripts/list-servers.sh`

Lists the servers known by `terraform state pull` and their public IP
addresses.

This will only work after running `terraform init` as described above.

### `scripts/run-ansible-playbooks.sh`

Updates the configuration of existing servers (pulled from the Terraform
inventory) using Ansible.

### `scripts/ssh-config.sh`

Generates a configuration block for your `~/.ssh/config` file that will make
commands like the following work as expected:

```
ssh projectname.www_wwwfiles
```

The convention is `projectname.SERVERNAME_USERNAME`.  To generate a config
block for the `root` user instead, do `scripts/ssh-config.sh ROOT` and then run
e.g. `ssh projectname.static_ROOT`.

### `scripts/update-ssh-config.sh`

Updates your `~/.ssh/config` to make commands like
`ssh projectname.www_wwwfiles`
work as expected.  Like `scripts/ssh-config.sh`, it also accepts `ROOT`.

### `scripts/update-everything.sh`

Runs both Terraform and Ansible.  One-stop command for setting up a new server
after including its details in the configuration files.

Note, even though this script is a single command, it is not fully automatic
from start to finish.  Terraform will prompt you to apply any changes, and
Ansible will prompt you to accept SSH host keys for new servers.

## Why?

The alternative is a manual process to create and set up servers.  This takes a
while, and it basically guarantees that our servers will not be "equal" and
that we will miss things when we update them.

### Why this approach?

Terraform is
[designed to create and destroy servers](https://www.terraform.io/intro/vs/chef-puppet.html)
while configuration management tools like Ansible are designed to manage server
configuration.

Terraform was chosen because of its approach of inspecting _existing_ resources
and _desired_ resources, and then planning and executing the changes to turn
the _existing_ state into the _desired_ state.  It always shows you exactly
what it's going to do before it does it, which is a big benefit when performing
potentially destructive actions.

Ansible was chosen because of its
[design goals](https://en.wikipedia.org/wiki/Ansible_%28software%29#Design_goals)
and because it is easy to install into a project without affecting the rest of
the computer.

To bridge these two tools (i.e. feed a list of Terraform-created servers into
Ansible so that it can manage their configuration), an approach similar to
[this article](https://nicholasbering.ca/tools/2018/01/08/introducing-terraform-provider-ansible/)
is used, implemented as a local script stored in this repository
(`terraform-inventory.py`).
