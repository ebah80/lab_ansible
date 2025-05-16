## Download the resources

```
git clone https://github.com/ebah80/lab_ansible.git
```

## Build the environment
```
docker-compose up -d
```

## Login to the orchestrator
```
docker exec -it ansible-orchestrator sh
```

## First run: PING > PONG
```
ansible all -i inventory.ini -m ping
```

## Facts
```
ansible sshnode -i inventory.ini -m setup
ansible sshnode -i inventory.ini -m setup -a "filter=ansible_distribution*"
```

## Play with the inventory
```
ansible -i inventory.ini all --list-hosts
ansible -i inventory.ini "barcelona:tokyo" --list-hosts
ansible -i inventory.ini "barcelona:&tokyo" --list-hosts
ansible -i inventory.ini --list "bar*" --list-hosts
ansible -i inventory.ini --list tokyo --list-hosts
```
- https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html

### Inventory: limit
```
ansible -i inventory.ini all -m ping --limit "demo"
```

### Inventory: list-hosts
```
ansible -i inventory.ini all -m ping --list-hosts
ansible -i inventory.ini all -m ping --limit "demo" --list-hosts
```

## Collection (or modules ...)

- https://docs.ansible.com/ansible/latest/collections/index.html

## ansible-playbook
```
ansible-playbook 001.yml -i inventory.ini --list-hosts
```

## Terminate the environment
```
docker-compose down -v
```
