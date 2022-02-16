IMPORT_VERSION:=20200211_9.0.3
IMPORT_DIR:=init_config/.current

status:
	docker-compose ps -a

start:
	docker-compose up -d

logs:
	docker-compose logs -f keycloak

logs-init:
	docker-compose logs -f keycloak-init

down:
	docker-compose down --remove-orphans

clean:
	make down
	docker volume rm --force stuart-keycloak_postgres_data
	make clean-import-files

init:
	make clean
	make prepare-import-files
	make launch-init
	echo "Waiting for service..."
	sleep 10
	echo "Waiting for service..."
	sleep 10
	echo "Waiting for service..."
	sleep 10
	echo "Waiting for service..."
	sleep 10
	make add-admin
	make login
	make import-stuart-realm
	make stop-init
	make clean-import-files	

prepare-import-files:
	mkdir -p ${IMPORT_DIR}
	cp init_config/${IMPORT_VERSION}/realm-export-*.json ${IMPORT_DIR}

clean-import-files:
	rm -rf ${IMPORT_DIR}

launch-init:
	docker-compose up -d keycloak-init

stop-init:
	docker-compose stop keycloak-init
	docker-compose rm --force keycloak-init

add-admin:
	docker-compose exec keycloak-init /opt/jboss/keycloak/bin/add-user-keycloak.sh -u ${KEYCLOAK_USER} -p ${KEYCLOAK_PASSWORD}
	docker-compose exec keycloak-init /opt/jboss/keycloak/bin/jboss-cli.sh --connect --command=:reload

login:
	docker-compose run --rm keycloak-cli-init config credentials --server http://keycloak-init:8080/auth --user ${KEYCLOAK_USER} --password ${KEYCLOAK_PASSWORD} --realm master

prepare-import-clients:
	docker-compose run --rm jq-processor -M '.authenticationFlows | map(select(.alias == "Browser With User Access Verification"))[0].id' /${IMPORT_DIR}/realm-export-only-clients.json > ${IMPORT_DIR}/old_id.json
	docker-compose run --rm keycloak-cli-init get authentication/flows -r stuart > ${IMPORT_DIR}/flows.json
	docker-compose run --rm jq-processor -M 'map(select(.alias == "Browser With User Access Verification"))[0].id' /${IMPORT_DIR}/flows.json > ${IMPORT_DIR}/new_id.json
	docker-compose run --rm jq-processor -M  --argfile new_id /${IMPORT_DIR}/new_id.json --argfile old_id /${IMPORT_DIR}/old_id.json '(.clients[] | select(.authenticationFlowBindingOverrides?.browser == $$old_id).authenticationFlowBindingOverrides.browser) |= $$new_id' /${IMPORT_DIR}/realm-export-only-clients.json > ${IMPORT_DIR}/realm-export-only-clients-updated.json

import-stuart-realm:
	make prepare-import-clients
	docker-compose run --rm keycloak-cli-init create partialImport -r stuart -s ifResourceExists=OVERWRITE -o -f /${IMPORT_DIR}/realm-export-only-clients-updated.json
	docker-compose run --rm keycloak-cli-init create partialImport -r stuart -s ifResourceExists=OVERWRITE -o -f /${IMPORT_DIR}/realm-export-only-groups-and-roles.json
