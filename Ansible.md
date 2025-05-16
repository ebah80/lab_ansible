## What is ansible?
Ansible is a configuration management orchestrator, meaning that it can configure a large set of resources (bare metal serevrs, virtual machines, firewalls, cloud resources)
Its primary role is to focus on configuration management of existing resources althought it can be used
Some characteristics are:
- **Agentless** – Unlike tools like Puppet or Chef, Ansible doesn’t require agents to be installed on managed nodes. It uses SSH (Linux) or WinRM (Windows) to execute tasks remotely.
- **Idempotency** – Running a playbook multiple times won’t cause unintended side effects; changes are only applied if needed.
- YAML-based Playbooks – Configurations and automation scripts are written in human-readable YAML, making them easy to understand and maintain.
- Modular with Built-in Modules – Comes with hundreds of modules for system administration, cloud provisioning, networking, security, etc.
- **Inventory Management** – Can manage dynamic and static inventories, supporting various sources like cloud providers or databases.
- Parallel Execution – Can execute tasks on multiple nodes simultaneously to speed up automation.
- Role-based Organization – Encourages reusable and structured configurations using "roles" to group tasks, variables, templates, and handlers.
- Security & Compliance – Uses Vault to encrypt sensitive data, and its agentless nature reduces security risks.
- **Event-driven Automation** – Can respond to events and integrate with tools like AWX/Ansible Tower for automation workflows.
## Who develops ansible?
Ansible is developed and maintained by Red Hat, a subsidiary of IBM
## Ansible license
Ansible is also an open-source project and follows an open-source licensing model under the GNU General Public License v3 (GPLv3).
https://github.com/ansible/ansible?tab=readme-ov-file#license
## Install ansible in AlmaLinux 9.5
https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip
```
# As root
dnf install python pip

# As user
python3 -m pip -V
python3 -m pip install --user ansible
```

Usually ansible is placed in:
- /home/username/.local/bin
Bash is configured in order to automatically add /home/username/.local/bin to PATH on startup if it finds it, otherwise you will have to permanently add to yout PATH environment variable
## Install ansible autocompletion
If you are working from command line it might be useful the auto completion package:
```
python3 -m pip install --user argcomplete
```
This is going to help while typing the commands pressing "tab".
## Run ansible
There are several ways to run ansible (https://docs.ansible.com/ansible/latest/command_guide/command_line_tools.html) we will focus mainly on these two binaries:
- ansible
- ansible-playbook
## ansible
Let's try an easy scenario.
We have two servers:
- france-demo-db-2
- france-demo-web-2

We want to run commands on them:
```
ansible --version
ansible server-name-or-ip-address -m shell -a 'hostname'
```
## inventory
Before proceeding further it's good to talk about inventories.
Ansible was designed to manage at scale, we say to manage "cattle" ([more here about the term](https://cloudscaling.com/blog/cloud-computing/the-history-of-pets-vs-cattle/)).
You don't want to run a single command for each of your servers (might be 10 servers, or 100, or 1000 or just a very big number).
Thus we need to feed ansible with an inventory (https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
The most simple form is an ini file but you can write inventories in:
- ini
- json
- yaml
This is how a simple inventory of two servers looks like:
``` inventory
[all]
france-collaudo-db3 ansible_host=172.18.14.31 ansible_user=automaton
france-collaudo-web-3 ansible_host=172.18.14.56 ansible_user=automaton
france-demo-db-2 ansible_host=172.18.14.104 ansible_user=automaton
france-demo-web-2 ansible_host=172.18.14.105 ansible_user=automaton

[collaudo]
france-collaudo-db3
france-collaudo-web-3

[collaudo:vars]
var_test=100

[demo]
france-demo-db-2
france-demo-web-2

[demo:vars]
var_test=900

[web]
france-collaudo-web-3
france-demo-web-2

[db]
france-collaudo-db3
france-demo-db-2
```

Save the inventory above in "hosts" file in the the same directory and let's now play a bit.

```
# select servers
ansible -i hosts all --list-hosts
ansible -i hosts "collaudo:demo" --list-hosts
ansible -i hosts "demo:&web" --list-hosts
ansible -i hosts --list "fran*" --list-hosts
ansible -i hosts --list france-demo-web-2 --list-hosts

# dry run
ansible -i hosts all -m yum -a "name=httpd state=present" --check

# dry run with check differences
ansible -i hosts "demo:&web" -m lineinfile -a "path=/etc/hosts line='192.168.1.10 myserver'" --check --diff

# run a command
## list affected servers by command
ansible -i hosts all -m ping --list-hosts

## ping on all servers in inventory
ansible -i hosts all -m ping

## ping only on demo servers in inventory
ansible -i hosts all -m ping --limit "demo"

## ping on all servers in inventory
ansible -i hosts --user=root --ask-become-pass -m shell -a 'hostname'

# run a command on the remote node
ansible -i hosts all --user=root --ask-become-pass -m shell -a 'hostname' --limit "demo"
```
## ansible facts
Ansible facts are system properties and environment details automatically gathered by the setup module when a playbook runs. These facts include information like OS, network interfaces, CPU, memory, disk space, and more.

```
ansible -i hosts france-demo-web-2 --user=yourusername --private-key=/directory/to/private_key_rsa -m setup
ansible -i hosts france-demo-web-2 --user=yourusername --private-key=/directory/to/private_key_rsa -m setup -a "filter=ansible_memfree_mb"
ansible -i hosts france-demo-web-2 --user=yourusername --private-key=/directory/to/private_key_rsa -m setup -a "filter=ansible_distribution*"
```
## ansible-playbook
```
ansible-playbook --version
```

This is the typical form of a playbook, with a header and a number of tasks:
```
---
- name: Title of the playbook
  hosts: all                         # define filters to select which servers are affected by the playbook
  gather_facts: yes                  # retrieve or skip facts gathering
  become: yes                        # switch to a super user by default
  become_user: root                  # define which super user to switch to
  
  tasks:

    - name: Disable SELinux          # task name
      ansible.posix.selinux:         # ansible module
        state: disabled              # arguments / parameters
      register: command_result

    - name: Disable TCP timestamp
      ansible.builtin.copy:
        src: ../files/etc_sysctl.d_disable-tcp-timestamp.conf
        dest: /etc/sysctl.d/disable-tcp-timestamp.conf
        mode: '0644'
        backup: yes

    - name: Reboot the server
      ansible.builtin.reboot:
        reboot_timeout: 600
        test_command: hostname
```

To try some playbooks you can clone this repository (USE ONLY AGAINST TEST SERVER):
```
git clone https://github.com/ADAM-ITALIA/infrastructure-automation.git
cd infrastructure-automation
```

Examples:
```
ansible-playbook main.yml -i inventory --ask-pass
ansible-playbook playbooks/60_cfg_mariadb.yml -i inventory --ask-pass
```
## ansible* defaults
- /etc/ansible/hosts – Default inventory file
- /etc/ansible/ansible.cfg – Config file, used if present
- ~/.ansible.cfg – User config file, overrides the default config if present
## ansible project skeleton
```
.
├── ansible.cfg
├── files
│   ├── etc_logrotate.d_loopContAuto
│   ├── etc_pam.d_sshd
│   ├── etc_profile.d_logout_inactive_users.sh
│   ├── etc_profile.d_motd.sh
│   ├── etc_rsyslog.conf
│   ├── etc_ssh_sshd_config
│   └── etc_ssh_sshd_config.d_50-redhat.conf
├── inventory
│   └── hosts
├── main.yml
├── playbooks
│   ├── 10_cfg_basic.yml
│   ├── 20_cfg_repositories.yml
│   ├── 30_cfg_packages.yml
│   ├── 35_cfg_postfix.yml
│   ├── 40_cfg_antivirus.yml
│   ├── 50_cfg_vault.yml
│   ├── 55_cfg_httpd_php.yml
│   ├── 60_cfg_mariadb.yml
│   ├── 65_cfg_percona.yml
│   ├── 70_cfg_nfs-server.yml
│   ├── 90_cfg_auth.yml
│   └── 99_cfg_dns.yml
└── templates
    ├── etc_exports.j2
    └── etc_postfix_generic.j2
```
## Ansible portal
https://semaphoreui.com/