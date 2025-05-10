# Monitoring Stack with Prometheus, Grafana & Exporters

This repository provides a fully automated monitoring stack using **Prometheus**, **Grafana**, **Alertmanager**, and various **exporters**. It is designed to be deployed effortlessly on any Ubuntu server using a single **bash script**.

## Features

- One-command setup using `setup-monitoring.sh`
- Includes:
  - Prometheus with persistent data and dynamic service discovery
  - Grafana with persistent dashboards and credentials
  - Alertmanager for managing alerts with email support (e.g., Gmail SMTP)
  - Node Exporter, Blackbox Exporter, SNMP Exporter
- Clean directory structure for configuration
- Nginx reverse proxy with subdomain-based access for all components
- Easy target management (via YAML files)

---

## Directory Structure

```
/opt/monitoring-stack/
├── setup-monitoring.sh
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   ├── alertrule.yml
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
├── nginx/
│   ├── conf.d/
│   │   ├── nginx-grafana.conf
│   │   ├── nginx-prometheus.conf
│   │   ├── nginx-portainer.conf
│   │   └── nginx-alertmanager.conf
│   ├── logs/
│   │   └── nginx_access.log
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

### 3. Run the Script
```bash
sudo ./setup-monitoring.sh
```

That’s it! Your full monitoring stack will be up and running.

---

## Access the Services

Assuming DNS is configured for the subdomains:

- **Grafana:** https://grafana.yourdomain.com/  
- **Prometheus:** https://prometheus.yourdomain.com/  
- **Alertmanager:** https://alertmanager.yourdomain.com/
- **Portainer:** https://portainer.yourdomain.com/

> Replace `yourdomain.com` with your actual domain name.

---

## Adding Monitoring Targets

To add a new device or service:

1. Open the respective YAML file in `prometheus/file_sd/`
2. Add the target IP/FQDN
3. Run:
```bash
docker compose restart prometheus
```

---

## Visual Architecture

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

---

## SMTP Alerting (Gmail)

Configure your `alertmanager.yml` with the following:

```yaml
smtp_smarthost: 'smtp.gmail.com:587'
smtp_from: 'your-email@gmail.com'
smtp_auth_username: 'your-email@gmail.com'
smtp_auth_password: 'app-password'  # Use App Password if 2FA enabled
```

> **Note:** Avoid using your main Gmail password. Use [Google App Passwords](https://support.google.com/accounts/answer/185833).

---

## License

MIT License – use freely with attribution.

---

## Contributing

PRs and suggestions are welcome! If you want more exporter support or new dashboards, feel free to open an issue.