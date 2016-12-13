#!/bin/bash

main() {
  local database_yml_path="$PWD/config/database.yml"

  if [ -f "$database_yml_path" ]; then
    debug 'config/database.yml already exists and will be overwritten'
  fi

  if [ -z "$WERCKER_RAILS_DATABASE_YML_POSTGRESQL_MIN_MESSAGE" ]; then
    export WERCKER_RAILS_DATABASE_YML_POSTGRESQL_MIN_MESSAGE="warning"
  fi

  if [ -z "$WERCKER_RAILS_DATABASE_YML_MYSQL_COLLATION" ]; then
    export WERCKER_RAILS_DATABASE_YML_MYSQL_COLLATION="utf8_general_ci"
  fi

  if [ -n "$WERCKER_RAILS_DATABASE_YML_SERVICE" ]; then
    info "Skipping autodetection; service option set: $WERCKER_RAILS_DATABASE_YML_SERVICE"

    case "$WERCKER_RAILS_DATABASE_YML_SERVICE" in
      postgresql|postgresql-legacy)
        generate_postgresql_legacy "$database_yml_path"
        ;;
      postgresql-docker)
        generate_postgresql_docker "$database_yml_path"
        ;;
      postgresql-local)
        generate_postgresql_local "$database_yml_path"
        ;;
      mysql|mysql-legacy)
        generate_mysql_legacy "$database_yml_path"
        ;;
      mysql-docker)
        generate_mysql_docker "$database_yml_path"
        ;;
      *)
        fail 'Invalid service; currently supported: postgresql, postgresql-legacy, postgresql-docker, postgresql-local, mysql, mysql-legacy, mysql-docker'
        ;;
    esac
    return
  fi

  info "Auto detecting service"

  # Check if there is a linked docker postgresql instance
  if [ -n "$POSTGRES_PORT_5432_TCP_ADDR" ]; then
    generate_postgresql_docker "$database_yml_path"
    return
  fi

  # Check if there is a linked docker mysql instance
  if [ -n "$MYSQL_PORT_3306_TCP_ADDR" ]; then
    generate_mysql_docker "$database_yml_path"
    return
  fi

  # Check if there is a legacy postgresql box
  if [ -n "$WERCKER_POSTGRESQL_HOST" ]; then
    generate_postgresql_legacy "$database_yml_path"
    return
  fi

  # Check if there is a legacy mysql box
  if [ -n "$WERCKER_MYSQL_HOST" ]; then
    generate_mysql_legacy "$database_yml_path"
    return
  fi

  # Check if WERCKER_POSTGRESQL_DATABASE is set to create local instance (deprecated)
  if [ -n "$WERCKER_POSTGRESQL_DATABASE" ]; then
    generate_postgresql_local "$database_yml_path"
    return
  fi

  fail 'Unable to auto detect service; please set "service" option'
}

# generate_postgresql_docker $location
# generate a database.yml based on docker links
generate_postgresql_docker() {
  local location="${1:?'location is required'}"

  if [ -z "$POSTGRES_ENV_POSTGRES_PASSWORD" ]; then
    warn "POSTGRES_PASSWORD env var for the postgres service is not set"
  fi

  info "Generating postgresql docker template"
  tee "$location" << EOF
test:
    adapter: <%= ENV['WERCKER_POSTGRESQL_ADAPTER'] || 'postgresql' %>
    encoding: "utf8"
    database: <%= ENV['POSTGRES_ENV_POSTGRES_DB'] || ENV['POSTGRES_ENV_POSTGRES_USER'] || 'postgres' %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['POSTGRES_ENV_POSTGRES_USER'] || 'postgres' %>
    password: <%= ENV['POSTGRES_ENV_POSTGRES_PASSWORD'] %>
    host: <%= ENV['POSTGRES_PORT_5432_TCP_ADDR'] %>
    port: <%= ENV['POSTGRES_PORT_5432_TCP_PORT'] %>
    min_messages: $WERCKER_RAILS_DATABASE_YML_POSTGRESQL_MIN_MESSAGE
EOF
}

# generate_postgresql_legacy $location
# generate a database.yml based on legacy wercker box.
generate_postgresql_legacy() {
  local location="${1:?'location is required'}"

  info "Generating postgresql legacy template"
  tee "$location" << EOF
test:
    adapter: <%= ENV['WERCKER_POSTGRESQL_ADAPTER'] || 'postgresql' %>
    encoding: "utf8"
    database: <%= ENV['WERCKER_POSTGRESQL_DATABASE'] %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['WERCKER_POSTGRESQL_USERNAME'] %>
    password: <%= ENV['WERCKER_POSTGRESQL_PASSWORD'] %>
    host: <%= ENV['WERCKER_POSTGRESQL_HOST'] %>
    port: <%= ENV['WERCKER_POSTGRESQL_PORT'] %>
    min_messages: $WERCKER_RAILS_DATABASE_YML_POSTGRESQL_MIN_MESSAGE
EOF
}

# generate_postgresql_local $location
# generate a database.yml based on local postgresql instance (deprecated).
generate_postgresql_local() {
  local location="${1:?'location is required'}"

  info "Generating postgresql local template"
  warn "Local postgresql database.yml is now deprecated. Consider copying a static file, or fork this step."
  tee "$location" << EOF
test:
    adapter: <%= ENV['WERCKER_POSTGRESQL_ADAPTER'] || 'postgresql' %>
    encoding: "utf8"
    database: <%= ENV['WERCKER_POSTGRESQL_DATABASE'] %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['WERCKER_POSTGRESQL_USERNAME'] %>
    password: <%= ENV['WERCKER_POSTGRESQL_PASSWORD'] %>
    min_messages: $WERCKER_RAILS_DATABASE_YML_POSTGRESQL_MIN_MESSAGE
EOF
}

# generate_mysql_docker $location
# generate a database.yml based on docker links
generate_mysql_docker() {
  local location="${1:?'location is required'}"

  if [ -z "$MYSQL_ENV_MYSQL_DATABASE" ]; then
    warn "MYSQL_DATABASE env var for the mysql service is not set"
  fi

  if [ -z "$MYSQL_ENV_MYSQL_USER" ]; then
    warn "MYSQL_USER env var for the mysql service is not set"
  fi

  if [ -z "$MYSQL_ENV_MYSQL_PASSWORD" ]; then
    warn "MYSQL_PASSWORD env var for the mysql service is not set"
  fi

  info "Generating mysql docker template"
  tee "$location" << EOF
test:
    adapter: mysql2
    encoding: utf8
    collation: $WERCKER_RAILS_DATABASE_YML_MYSQL_COLLATION
    database: <%= ENV['MYSQL_ENV_MYSQL_DATABASE'] %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['MYSQL_ENV_MYSQL_USER'] %>
    password: <%= ENV['MYSQL_ENV_MYSQL_PASSWORD'] %>
    host: <%= ENV['MYSQL_PORT_3306_TCP_ADDR'] %>
    port: <%= ENV['MYSQL_PORT_3306_TCP_PORT'] %>
EOF
}

# generate_mysql_legacy $location
# generate a database.yml based on legacy wercker box.
generate_mysql_legacy() {
  local location="${1:?'location is required'}"

  info "Generating mysql legacy template"
  tee "$location" << EOF
test:
    adapter: mysql2
    encoding: utf8
    collation: $WERCKER_RAILS_DATABASE_YML_MYSQL_COLLATION
    database: <%= ENV['WERCKER_MYSQL_DATABASE'] %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['WERCKER_MYSQL_USERNAME'] %>
    password: <%= ENV['WERCKER_MYSQL_PASSWORD'] %>
    host: <%= ENV['WERCKER_MYSQL_HOST'] %>
    port: <%= ENV['WERCKER_MYSQL_PORT'] %>
EOF
}

main;
