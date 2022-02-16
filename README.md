# Stuart Keycloak

Dockerized local instance of [Keycloak](https://www.keycloak.org/) with JSON-based [configuration utility](https://github.com/adorsys/keycloak-config-cli).

This project is owned by :sparkles:DevEx Convoy:sparkles:. Feel free to use [#convoy-developer-experience channel](https://gostuart.slack.com/archives/C02ETTN5RGB) to reach us out.

## Setup

Prerequisites:

* [Docker](https://docs.docker.com/get-docker/) :whale:
* [Docker Compose](https://docs.docker.com/compose/install/)

Copy files with env variables:

```
$ cp .env.sample .env
$ cp .client_secrets.env.sample .client_secrets.env
```

If you have already `docker` and `docker-compose` installed, you can start `Keycloak` with underlaying DB by executing:
```$ docker-compose up```
To make sure that services are up, visit [Keycloak admin](`http://localhost:1080/auth`) afterwards.

## Migrating configuration of Keycloak

:warning: Instead of configuring `Keycloak` via its GUI, please use JSON files under `./keycloak_config/migrations`. They are generated with:

```
$ bin/generate_migration -h
Usage: generate_migration [migration_name]
migration_name has to be snake_cased and can't contain digits or whitespaces.

# For example:
$ bin/generate_migation snake_cased_migration_name
```
Migrations are performed by [Keycloak Config CLI](https://github.com/adorsys/keycloak-config-cli), so check the docs and [examples](https://github.com/adorsys/keycloak-config-cli/tree/main/src/test/resources/import-files) to learn more about the syntax. When the content of migration is defined, you can run them with:
```
$ bin/migrate
```
The script finds pending migrations, applies the changes and generates a new dump file that will be used to configure other instances. Before you push new migration into the repository, please make sure that the new dump file is not contaminated with unneeded information.

### Keeping secrets in secret

`Keycloak` does not allow exporting secrets, but you can import them. Secrets are stored in a migration file, but obviously, keeping them in plain text is reckless. We avoid it by using [variable substitution](https://github.com/adorsys/keycloak-config-cli#variable-substitution).

If your migration contains client secret, please do the following:

1. Replace the "secret" in the migration file with the variable:
    ```
      {
        "enabled": true,
        "realm": "stuart",
        "clients": [
          {
            "clientId": "PlanEx",
            "name": "Planet Express Inc",
            "description": "Our crew is replaceable, your package isn't!",
            "enabled": true,
            "clientAuthenticatorType": "client-secret",
            "secret": "$(env:PLAN_EX_CLIENT_SECRET)", # Pick the right name for your variable
            "redirectUris": [
              "*"
            ],
            "webOrigins": [
              "*"
            ]
          }
        ],
        "attributes": {
          "custom": "test-step01"
        }
      }
    ```
2. Add your variable to the `.client_secrets.env` and `.client_secrets.env.sample` files. These will be used accordingly in your local env and as a sample for other developers.
    ```
    # .client_secrets.env
    ...
    PLAN_EX_CLIENT_SECRET="bite-my-shiny-metal-ass"

    ```
    ```
    # .client_secrets.env.sample
    ...
    PLAN_EX_CLIENT_SECRET="bite-my-shiny-metal-ass"
    ```
3. Run the migration, so you know that the substitution worked as expected. Using the `Keycloak Admin Console`>`Clients` tab, you can verify the result.
4. Add your variable to all the Consul environments under `TBA` directory. If it's a production environment, please put more effort into generating a complex and safe one. This step is critical because the deployment fails when the variable is not set. If you don't know how to do it, read: [View and set runtime configuration for a Stuart project](https://stuart-team.atlassian.net/wiki/spaces/EN/pages/906985485/View+and+set+runtime+configuration+for+a+Stuart+project#%F0%9F%94%90-How-to-get-the-Consul-token-from-Vault).

## Deployment

TODO