# ansible-splunk

Staged Ansible automation to build and harden a single Splunk Enterprise host on Ubuntu Server (minimal install).

## What this does

This project deploys Splunk in 3 stages:

1. `00-prereqs.yml`
- OS patching and baseline packages
- SSH baseline controls
- UFW baseline policy and access rules
- Security/ops services (`ufw`, `fail2ban`, `auditd`, `rsyslog`, `cron`)

2. `10-install.yml`
- Splunk service account and directory setup
- Splunk package download
- SHA512 integrity verification
- Package install and first start
- Boot-start enablement

3. `20-configure.yml`
- Runtime guardrails (`nofile`, restart policy)
- Splunk service detection and startup handling
- Backup script deployment
- Root cron backup schedule
- Optional admin password seeding (`user-seed.conf`)

## Repository layout

- `ansible.cfg`: Ansible defaults for this project
- `inventories/lab/hosts.yml`: target hosts/group (`splunk_instance`)
- `group_vars/all.yml`: non-secret variables
- `group_vars/vault.yml`: encrypted secrets (gitignored)
- `playbooks/site.yml`: runs all stages in order
- `playbooks/00-prereqs.yml`
- `playbooks/10-install.yml`
- `playbooks/20-configure.yml`
- `playbooks/90-validate.yml`: post-deploy validation with per-host reports
- `templates/backup-splunk-etc.sh.j2`

## Prerequisites

- Ansible control node with network reachability to targets
- SSH access to targets with sudo privileges
- `community.general` collection for UFW module

Install collection:

```bash
ansible-galaxy collection install community.general
```

## Docker control node setup

If running from a Docker Ubuntu container, install these packages inside the container:

```bash
apt update && apt install -y ansible python3 openssh-client sshpass git
ansible-galaxy collection install community.general
```

Optional troubleshooting tools:

```bash
apt install -y iputils-ping dnsutils
```

## Configure inventory

Edit:

- `inventories/lab/hosts.yml`
- `group_vars/all.yml`

Set:

- hostnames/IPs
- `ansible_user`
- Splunk version/build variables
- backup schedule values

## Create `vault.yml` (required)

Create encrypted credentials file using this exact flow:

`/work/ansible-splunk` should be your working directory before running these commands.

```bash
cd /work/ansible-splunk
cat > /tmp/vault-plain.yml <<'EOF'
ansible_password: "StrongPassword"
ansible_become_password: "StrongPassword"
EOF

ansible-vault encrypt /tmp/vault-plain.yml --output group_vars/vault.yml
rm -f /tmp/vault-plain.yml
```

Notes:

- `group_vars/vault.yml` is gitignored and must be created per environment.
- Use `ansible-vault rekey group_vars/vault.yml` to rotate vault password later.

## Run playbooks

Run all stages:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

Run stage by stage:

```bash
ansible-playbook playbooks/00-prereqs.yml --ask-vault-pass
ansible-playbook playbooks/10-install.yml --ask-vault-pass
ansible-playbook playbooks/20-configure.yml --ask-vault-pass
```

## Manual test (post-deploy)

On target host:

```bash
sudo -u splunk /opt/splunk/bin/splunk status
sudo ufw status numbered
systemctl is-active ufw fail2ban auditd rsyslog cron
systemctl list-unit-files | grep -i splunk
sudo crontab -l | grep "splunk etc backup"
ls -lah /srv/splunk/backups
```

## Automated validation and report

Run automated validation across the inventory:

```bash
ansible-playbook playbooks/90-validate.yml --ask-vault-pass
```

Reports are written per host to:

- `reports/<inventory_hostname>-validation.txt`
