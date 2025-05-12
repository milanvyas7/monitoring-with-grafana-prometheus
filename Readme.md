# Monitoring Stack with Prometheus, Grafana & Exporters

A fully automated, containerized monitoring stack for **Linux/Windows servers, network devices, and web services** using **Prometheus**, **Grafana**, **Alertmanager**, and exporters. Designed for easy deployment on Ubuntu with a single script.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Prometheus Targets](#prometheus-targets)
  - [Alerting Rules](#alerting-rules)
  - [Alertmanager Email Setup](#alertmanager-email-setup)
  - [Nginx Reverse Proxy](#nginx-reverse-proxy)
- [Accessing Services](#accessing-services)
- [Adding/Editing Monitoring Targets](#addingediting-monitoring-targets)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **One-command setup** with `setup-monitoring.sh`
- **Prometheus** for metrics collection and alerting
- **Grafana** for dashboards and visualization
- **Alertmanager** for alert notifications (email/SMS)
- **Node Exporter** for Linux host metrics
- **Blackbox Exporter** for HTTP, ICMP, and SSL monitoring
- **SNMP Exporter** for network devices
- **Windows Exporter** for Windows hosts
- **Nginx** reverse proxy with subdomain-based routing
- **Portainer** for Docker management UI
- **Dynamic target discovery** via YAML files
- **Persistent storage** for Prometheus and Grafana data

---

## Architecture Overview

```
                +--------------------------+
                |      NGINX Reverse Proxy |
                +-----------+--------------+
                            |
       +--------------------+------------------------+
       |           |                 |               |
  Grafana      Prometheus        Alertmanager    Portainer
   (3000)        (9090)            (9093)          (9000)
```

- **Nginx** routes traffic to each service based on subdomain.
- **Prometheus** scrapes exporters and stores metrics.
- **Grafana** visualizes data from Prometheus.
- **Alertmanager** sends notifications based on alert rules.
- **Portainer** provides a web UI for Docker management.

---

## Prerequisites

- Ubuntu 20.04/22.04 server (root or sudo access)
- Docker & Docker Compose (installed automatically by script)
- Open ports: 80, 443, 3000, 9090, 9093, 9000, 9100, 9115, 9116, 8080
- (Optional) DNS records for subdomains (grafana, prometheus, alertmanager, portainer)

---

## Directory Structure

```
/opt/monitoring-stack/
├── setup-monitoring.sh
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   ├── alert.rules.yml
│   └── file_sd/
│       ├── node_targets.yml
│       ├── blackbox_targets.yml
│       ├── win_targets.yml
│       ├── snmp_targets.yml
│       └── ping_targets.yml
├── blackbox/
│   └── config.yml
├── alertmanager/
│   └── alertmanager.yml
├── portainer-data/
├── grafana/
│   ├── data/                            ← Persistent Grafana data (UID 472)
│   ├── dashboards/                      ← Dashboard JSON files
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml
│       └── dashboards/
│           └── dashboard.yml
├── nginx/
│   ├── conf.d/
│   │   ├── nginx-grafana.conf
│   │   ├── nginx-prometheus.conf
│   │   ├── nginx-portainer.conf
│   │   └── nginx-alertmanager.conf
│   ├── logs/
│   │   ├── nginx_access.log
│   │   └── nginx_error.log
│   └── certs/              <-- Optional if using HTTPS
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/milanvyas7/monitoring-with-grafana-prometheus.git
cd monitoring-with-grafana-prometheus
```

### 2. Make Script Executable

```bash
chmod +x setup-monitoring.sh
```

### 3. Run the Setup Script

```bash
sudo ./setup-monitoring.sh
```

- Installs Docker & Compose if missing
- Sets up directory structure and permissions
- Copies configuration files
- Launches all containers

---

## Configuration

### Prometheus Targets

- **Linux hosts:** Edit [`node_targets.yml`](node_targets.yml)
- **Windows hosts:** Edit [`win_targets.yml`](win_targets.yml)
- **Network devices (SNMP):** Edit [`snmp_targets.yml`](snmp_targets.yml)
- **Web/SSL/ICMP checks:** Edit [`blackbox_targets.yml`](blackbox_targets.yml) and [`ping_targets.yml`](ping_targets.yml)

Each file uses YAML format. Example for Linux hosts:
```yaml
- targets: ['localhost:9100']
  labels:
    name: 'Docker machine'
    site: 'VM'
```

### Alerting Rules

- Defined in [`alert.rules.yml`](alert.rules.yml)
- Includes alerts for instance down, high CPU, low memory, disk space, SSL expiry, website down, etc.
- Customize or add rules as needed.

### Alertmanager Email Setup

- Configure SMTP in [`alertmanager.yml`](alertmanager.yml):

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'app-password'
  smtp_require_tls: true
```
> Use [Google App Passwords](https://support.google.com/accounts/answer/185833) if using Gmail with 2FA.

### Nginx Reverse Proxy

- Nginx config files are in [`nginx/conf.d/`](nginx/conf.d/)
- Each service is mapped to a subdomain (edit `server_name` as needed)
- SSL can be enabled by uncommenting and configuring the SSL sections

---

## Accessing Services

After setup, access via your browser:

- **Grafana:** http://grafana.yourdomain.com/ (default: admin/admin)
- **Prometheus:** http://prometheus.yourdomain.com/
- **Alertmanager:** http://alertmanager.yourdomain.com/
- **Portainer:** http://portainer.yourdomain.com/

> Replace `yourdomain.com` with your actual domain or server IP.

---

## Adding/Editing Monitoring Targets

1. Edit the relevant YAML file in `/opt/monitoring-stack/prometheus/file_sd/`
2. Add or remove targets as needed
3. Reload Prometheus:

```bash
cd /opt/monitoring-stack
docker compose restart prometheus
```

---

## Troubleshooting

- **Check container logs:**  
  `docker compose logs <service-name>`
- **Prometheus not scraping targets:**  
  - Verify target YAML files and paths
  - Check Prometheus UI for scrape errors
- **No email alerts:**  
  - Check SMTP settings in `alertmanager.yml`
  - Check Alertmanager logs
- **Nginx 502/504 errors:**  
  - Ensure backend containers are running
  - Check Nginx logs in `/opt/monitoring-stack/nginx/logs/`

---

## Contributing

- PRs and suggestions are welcome!
- For new exporters or dashboards, open an issue or submit a pull request.

---

## License

MIT License – use freely with attribution.

---

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)
- [SNMP Exporter](https://github.com/prometheus/snmp_exporter)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [Portainer](https://www.portainer.io/)