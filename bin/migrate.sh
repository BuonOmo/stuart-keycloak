#!/bin/sh
set -e
trap "rm -rf $PENDING_MIGRATIONS_DIR; rm -f $NEW_MIGRATION_REGISTRY_FILE" EXIT

# Directory with keycloak config migrations
MIGRATIONS_DIR=./keycloak_config/migrations

# Temporal directory with pending keycloak config migrations
PENDING_MIGRATIONS_DIR="$MIGRATIONS_DIR/.pending"

# File that stores current state of the migration
MIGRATION_REGISTRY_FILE=./keycloak_config/.migration_registry

# Temp file that stores pending migrations
NEW_MIGRATION_REGISTRY_FILE=./keycloak_config/.migration_registry_new

setup_migrations() {
    echo "Setting up pending migrations"
    # Create temp file with pending migrations
    ls $MIGRATIONS_DIR > $NEW_MIGRATION_REGISTRY_FILE

    # Copy pending migrations into PENDING_MIGRATIONS_DIR
    if test -f "$MIGRATION_REGISTRY_FILE"; then
        mkdir -p $PENDING_MIGRATIONS_DIR
        PENDING_MIGRATIONS=`diff --left-column -n $MIGRATION_REGISTRY_FILE $NEW_MIGRATION_REGISTRY_FILE \
        | grep "json" \
        | xargs -L1 printf "$MIGRATIONS_DIR/%s "`

        # Print pending migration names or exit if there is none
        if [ -z "$PENDING_MIGRATIONS" ]
        then
            echo "There are no pending migrations"
            cleanup
            exit 0
        else
            echo "Pending migrations found:"
            for migration_name in $(echo $PENDING_MIGRATIONS | tr " " "\n")
            do
                echo $migration_name
            done
            cp $PENDING_MIGRATIONS $PENDING_MIGRATIONS_DIR
        fi
    fi
}

run_migrations(){
    echo "Running migrations"
    docker-compose run -e IMPORT_PATH=$PENDING_MIGRATIONS_DIR keycloak-config-cli
}

generate_snapshot_file(){
    echo "Generating snapshot file"
    # TODO
}

cleanup() {
    echo "Cleaning up"
    cp $NEW_MIGRATION_REGISTRY_FILE $MIGRATION_REGISTRY_FILE
    rm -rf $PENDING_MIGRATIONS_DIR; rm -f $NEW_MIGRATION_REGISTRY_FILE
}

setup_migrations
run_migrations
generate_snapshot_file
cleanup

exit 0