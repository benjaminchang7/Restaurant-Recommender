pgbouncer:
  databases:
    restaurant_db: host=${DB_HOST} port=5432 dbname=${DB_NAME}

  users:
    - name: ${DB_USER}
      password:
        valueFrom:
          secretKeyRef:
            name: pgbouncer-env
            key: POSTGRESQL_PASSWORD

auth_type: md5
pool_mode: transaction
max_client_conn: 1000
default_pool_size: 100
reserve_pool_size: 20
reserve_pool_timeout: 2

config:
  adminUser: ${DB_USER}
  adminPassword: ${DB_PASSWORD}
