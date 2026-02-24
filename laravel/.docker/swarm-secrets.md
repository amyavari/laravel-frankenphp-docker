### ✅ Required Docker Swarm secrets

| Secret name | Laravel env     | Why                                          |
| ----------- | --------------- | -------------------------------------------- |
| `app_key`   | `APP_KEY`       | **Must be static** for encryption & sessions |
| `db_name`   | `DB_DATABASE`   | DB name                                      |
| `db_user`   | `DB_USERNAME`   | DB auth                                      |
| `db_pass`   | `DB_PASSWORD`   | DB auth                                      |
| `mail_host` | `MAIL_HOST`     | Mail                                         |
| `mail_user` | `MAIL_USERNAME` | Mail                                         |
| `mail_pass` | `MAIL_PASSWORD` | Mail                                         |

---

### ✅ Optional but common

| Secret                  | When           |
| ----------------------- | -------------- |
| `redis_password`        | If using Redis |
| `sentry_dsn`            | Error tracking |
| `aws_access_key_id`     | S3             |
| `aws_secret_access_key` | S3             |

---
