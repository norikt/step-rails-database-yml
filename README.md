# Rails database yml

Generates a `config/database.yml` file with the environment information from
your database service.

For this step you need to have a mysql or postgres. See the
[services](http://devcenter.wercker.com/learn/wercker-yml/02_sections.html#services)
on wercker devcenter for more information about services.

# What's new

- Add support for the ewok stack.

# Options

- `service` This option is not required. If set, it will load the template from
the specified service; otherwise, it will infer the service from the
environment.
- `postgresql-min-message` (optinal, default: `warning`): Set the min_messages
parameter in the postgresql template.
- `mysql-collation` (optinal, default: `utf8_general_ci`): Set collation
parameter in mysql template.

# Supported services

Currently `wercker/postgresql` and `wercker/mysql` for the old stack are
supported. No further configuration is required for these services.

The following docker containers are supported in the new stack: `postgres` and
`mysql`. Both have some required and recommended environment variables.

The `postgresql` container requires the `POSTGRES_PASSWORD` environment variable
to be set. The other environment variables are `POSTGRES_USER` and
`POSTGRES_DB`. All environment variables are used in this step, or use the same
defaults as the container.

The `mysql` container requires the `MYSQL_ROOT_PASSWORD`, but this password
won't be used by this step. Make sure you also set `MYSQL_DATABASE`,
`MYSQL_USER` and `MYSQL_PASSWORD`. These are the environment variables that will
be used by this step.

# Example

The following `wercker.yml`:

``` yaml
box: wercker/ruby
services:
  - wercker/postgresql
build:
  steps:
    - rails-database-yml
```

Will generate the following `config/database.yml`:

``` yaml
test:
    adapter: postgresql
    encoding: "utf8"
    database: <%= ENV['WERCKER_POSTGRESQL_DATABASE'] %><%= ENV['TEST_ENV_NUMBER'] %>
    username: <%= ENV['WERCKER_POSTGRESQL_USERNAME'] %>
    password: <%= ENV['WERCKER_POSTGRESQL_PASSWORD'] %>
    host: <%= ENV['WERCKER_POSTGRESQL_HOST'] %>
    port: <%= ENV['WERCKER_POSTGRESQL_PORT'] %>
    min_messages: warning
```

# Changelog

## 1.2.0

- Add `mysql-collation` parameter

## 1.1.0

- Add support for the ewok stack.

## 1.0.0

- Add `postgresql-min-message` parameter

## 0.9.3

- Use `$PWD` instead of `$WERCKER_ROOT_DIR`

## 0.9.2

- Adds environment variable `TEST_ENV_NUMBER` to the database name

## 0.9.1

- Initial version
