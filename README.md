# LeadCMS Deployment Guide (Sample Docker Compose)

This document provides a sample deployment approach for LeadCMS using Docker Compose. It is intended as a reference for DevOps teams to understand how the CMS and its dependencies can be orchestrated for local development, evaluation, or as a starting point for production deployments.

---

## Important Notes for DevOps Teams

- **The provided `docker-compose.yml` is a sample.**  
  It demonstrates how to run LeadCMS and its dependencies (PostgreSQL, Elasticsearch, Kibana) together for convenience.
- **You are not required to use this exact setup.**  
  In production, you may (and often should) host PostgreSQL, Elasticsearch, and other services separately, using managed services or your own infrastructure.
- **Backups, reliability, and scalability are not addressed in this sample.**  
  The sample does not include production-grade features such as automated backups, high availability, monitoring, or scaling. These must be implemented by your DevOps team according to your organization's requirements.
- **Sensitive data:**  
  The `.env` file contains secrets and credentials. Never commit it to version control.

---

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop) installed and running
- [Docker Compose](https://docs.docker.com/compose/) (if not included with Docker Desktop)
- (Optional) [PowerShell](https://docs.microsoft.com/en-us/powershell/) for Windows users

---


## 1. Clone the Repository

```bash
git clone https://github.com/LeadCMS/leadcms.deploy.git
cd leadcms.deploy
```

---


## 2. Generate Environment Variables

LeadCMS uses a `.env` file for configuration. You **must** generate this file before starting the containers.

### On Linux/macOS

Run the provided shell script:

```bash
chmod +x generate-env.sh
./generate-env.sh
```

### On Windows

Run the PowerShell script:

```powershell
.\generate-env.ps1
```

- The script will:
  - Read `.env.sample`
  - Generate secure random secrets and passwords
  - Write a new `.env` file

**Note:** If a `.env` file already exists, you will be prompted before overwriting.

---

## 3. Review and Customize `.env`

- Open `.env` in your editor.
- **It is important to set all email-related variables:**
  - `EMAIL__USERNAME` (your SMTP username)
  - `EMAIL__PASSWORD` (your SMTP password)
  - `EMAIL__SERVER` (SMTP server address)
  - `EMAIL__PORT` (SMTP server port)
  - `EMAIL__USESSL` (set to `true` if your SMTP requires SSL)
- Also review and update:
  - `CORS__ALLOWEDORIGINS__*` (allowed origins for your frontend)
  - Any other settings specific to your environment

### Supported Languages

To configure a list of supported languages, add the following to your `.env` file:

```
SUPPORTEDLANGUAGES__0=en
SUPPORTEDLANGUAGES__1=de
```

You can add more languages by incrementing the index.

---


## 4. Start the Sample Stack

From the repository root, run:

```bash
docker-compose up -d
```

- This will start:
  - PostgreSQL (sample, local container)
  - LeadCMS core application

---

## 5. Access the Services

- **LeadCMS API:** [http://localhost:8080](http://localhost:8080)

---

## 6. Default Admin User

- Username: as set in `.env` (`DEFAULTUSERS__0__USERNAME`)
- Password: as generated in `.env` (`DEFAULTUSERS__0__PASSWORD`)
- Email: as set in `.env` (`DEFAULTUSERS__0__EMAIL`)

---


## 7. Stopping and Cleaning Up

To stop the stack:

```bash
docker compose down
```

To remove all data (Postgres/Elastic):

```bash
docker compose down -v
```

---

## Troubleshooting

### PostgreSQL Authentication Issues


If you encounter authentication errors when connecting to PostgreSQL, it may be due to an existing Docker volume containing an old database with a different password. In this case:

1. Stop all running containers:
  ```bash
  docker compose down
  ```
2. Remove all persistent data volumes (this will delete all data in Postgres and Elastic):
  ```bash
  docker compose down -v
  ```
3. Start the stack again:
  ```bash
  docker compose up -d
  ```
This will re-create the databases with the current credentials from your `.env` file.

---

## Plugin Mounting

To extend LeadCMS with plugins, you can mount external plugin directories into the container using Docker volumes. This allows you to:

- Attach custom plugins by mounting their directories into the `/app/plugins/YourPluginName` path inside the container.

**Plugin configuration:**  
Each plugin must also be defined in the plugin list in your `.env` file using indexed keys, for example:
```
PLUGINS__0=LeadCMS.Plugin.Site
```
Only plugins listed here will be loaded by the core application.

**How it works (theory):**

- In your Docker Compose file, define a named volume for each plugin you want to attach.
- Use the `volumes` section of your service to map the host directory (where your plugin code resides) to the appropriate path inside the container.

**For example:**
- To attach a plugin named `LeadCMS.Plugin.Site`, mount your host's plugin directory to `/app/plugins/LeadCMS.Plugin.Site`.

**Note:**  
Adjust the host paths to match your environment and ensure the plugin directory structure matches what LeadCMS expects.

This approach allows you to keep plugins outside of the container image, making updates and development easier.

---

## Deployment Considerations

- **Production deployments should not rely on the sample Docker Compose file.**
    - Use managed or production-grade PostgreSQL and Elasticsearch services.
    - Configure secure networking, firewalls, and access controls.
    - Implement automated backups and disaster recovery for all data stores.
    - Plan for monitoring, alerting, and log aggregation.
    - Consider scaling requirements and high availability.
    - Review and harden all secrets and credentials.
    - Use persistent storage for all stateful services.

- **The sample Docker Compose is best used for:**
    - Local development and testing
    - Evaluation and proof-of-concept deployments
    - As a reference for your own infrastructure-as-code

---


## Database Backup and Restore Scripts

This repository includes utility scripts for backing up and restoring your PostgreSQL database, available in both shell script and PowerShell versions:

### PostgreSQL Backup

Create a backup of your PostgreSQL database. Optionally, you can exclude user-related tables from the backup.

#### On Linux/macOS

```bash
./pg-backup.sh <database_name> [--exclude-user-tables]
```

Examples:
- Full backup: `./pg-backup.sh leadcms`
- Excluding user tables: `./pg-backup.sh leadcms --exclude-user-tables`

#### On Windows

```powershell
.\pg-backup.ps1 <database_name> [-ExcludeUserTables]
```

Examples:
- Full backup: `.\pg-backup.ps1 leadcms`
- Excluding user tables: `.\pg-backup.ps1 leadcms -ExcludeUserTables`

### PostgreSQL Restore

Restore a PostgreSQL database from a backup file. If the database does not exist, it will be created automatically.

#### On Linux/macOS

```bash
./pg-restore.sh <database_name> <backup_file>
```

#### On Windows

```powershell
.\pg-restore.ps1 <database_name> <backup_file>
```

### PostgreSQL Media Table Restore

Restore only the `media` table from a backup file into the specified database.

#### On Linux/macOS

```bash
./pg-restore-media.sh <database_name> <backup_file>
```

#### On Windows

```powershell
.\pg-restore-media.ps1 <database_name> <backup_file>
```

**Note:** All scripts use environment variables from your `.env` file for database credentials. Make sure your `.env` is up to date before running these scripts.

---

## Limitations of the Sample Setup

- **No backup or restore automation** for databases (only manual scripts are provided).
- **No high availability or failover** for any service.
- **No monitoring, alerting, or log aggregation** included.
- **No scaling or load balancing** configuration.
- **No SSL/TLS** for internal or external endpoints.
- **No production-grade security hardening**.

**Your DevOps team is responsible for addressing these areas in your deployment.**

---

## HTTPS, Static Sites, and Preview Hosting

For setting up SSL/TLS (HTTPS) using Let's Encrypt, as well as hosting static sites and preview servers, see the companion repository:  
[https://github.com/LeadCMS/leadcms.nginx](https://github.com/LeadCMS/leadcms.nginx)

This repository provides sample Nginx configurations and automation for secure deployments.

---

## Questions?

Open an issue or contact the maintainers.