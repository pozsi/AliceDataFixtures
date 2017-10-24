COVERS_VALIDATOR=php -d zend.enable_gc=0 vendor-bin/covers-validator/bin/covers-validator
PHP_CS_FIXER=php -d zend.enable_gc=0 vendor-bin/php-cs-fixer/bin/php-cs-fixer

.DEFAULT_GOAL := help

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


##
## Commands
##---------------------------------------------------------------------------

cleanup:		## Removes all created artefacts
cleanup:
	mysql -u root -e "DROP DATABASE IF EXISTS fidry_alice_data_fixtures;"
	mongo fidry_alice_data_fixtures --eval "db.dropDatabase();"

	git clean --exclude=.idea/ -fdx

refresh_mysql_db:	## Refresh the MySQL database used
refresh_mysql_db:
	mysql -u root -e "DROP DATABASE IF EXISTS fidry_alice_data_fixtures; CREATE DATABASE fidry_alice_data_fixtures;"

refresh_mongodb_db:	## Refresh the MongoDB database used
refresh_mongodb_db:
	mongo fidry_alice_data_fixtures --eval "db.dropDatabase();"

refresh_phpcr:		## Refresh the MongoDB PHPCR database used
refresh_phpcr: vendor-bin/doctrine_phpcr/bin/phpcrodm
	mysql -u root -e "DROP DATABASE IF EXISTS fidry_alice_data_fixtures; CREATE DATABASE fidry_alice_data_fixtures;"
	php vendor-bin/doctrine_phpcr/bin/phpcrodm jackalope:init:dbal --force
	php vendor-bin/doctrine_phpcr/bin/phpcrodm doctrine:phpcr:register-system-node-types

remove_sf_cache:	## Removes cache generated by Symfony
remove_sf_cache:
	rm -rf fixtures/Bridge/Symfony/cache/*

##
## Tests
##---------------------------------------------------------------------------

test:           				## Run all the tests
test: test_core	\
	  test_doctrine_bridge \
	  test_doctrine_odm_bridge \
	  test_doctrine_phpcr_bridge \
	  test_eloquent_bridge \
	  test_symfony_bridge \
	  test_symfony_doctrine_bridge \
	  test_symfony_eloquent_bridge \
	  test_symfony_doctrine_bridge_proxy_manager \
	  test_symfony_eloquent_bridge_proxy_manager

test_core:             				## Run the tests for the core library
test_core: vendor/phpunit \
		   vendor-bin/covers-validator/vendor
	$(COVERS_VALIDATOR)

	bin/phpunit

test_doctrine_bridge:				## Run the tests for the Doctrine bridge
test_doctrine_bridge: vendor-bin/doctrine/bin/phpunit \
				      refresh_mysql_db
	vendor-bin/doctrine/bin/doctrine orm:schema-tool:create

	vendor-bin/doctrine/bin/phpunit -c phpunit_doctrine.xml.dist

test_doctrine_odm_bridge:			## Run the tests for the Doctrine ODM bridge
test_doctrine_odm_bridge: vendor-bin/doctrine_mongodb/bin/phpunit \
						  refresh_mongodb_db
	vendor-bin/doctrine_mongodb/bin/phpunit -c phpunit_doctrine_mongodb.xml.dist

test_doctrine_phpcr_bridge:			## Run the tests for the Doctrine Mongodb PHPCR bridge
test_doctrine_phpcr_bridge: vendor-bin/doctrine_mongodb/bin/phpunit \
							refresh_phpcr
	vendor-bin/doctrine_phpcr/bin/phpunit -c phpunit_doctrine_phpcr.xml.dist

test_eloquent_bridge:				## Run the tests for the Eloquent bridge
test_eloquent_bridge: vendor-bin/eloquent/bin/phpunit \
					  refresh_mysql_db
	php bin/eloquent_migrate

	vendor-bin/eloquent/bin/phpunit -c phpunit_eloquent.xml.dist

test_symfony_bridge:				## Run the tests for the Symfony bridge
test_symfony_bridge: vendor-bin/eloquent/bin/phpunit \
					 vendor-bin/covers-validator/vendor \
					 remove_sf_cache
	$(COVERS_VALIDATOR) -c phpunit_symfony.xml.dist

	vendor-bin/symfony/bin/phpunit -c phpunit_symfony.xml.dist

test_symfony_doctrine_bridge:			## Run the tests for the Symfony Doctrine bridge
test_symfony_doctrine_bridge: vendor-bin/symfony/bin/phpunit \
							  remove_sf_cache \
							  refresh_mysql_db \
							  refresh_mongodb_db \
							  refresh_phpcr
	php bin/console doctrine:schema:create --kernel=DoctrineKernel

	vendor-bin/symfony/bin/phpunit -c phpunit_symfony_doctrine.xml.dist

test_symfony_eloquent_bridge:			## Run the tests for the Symfony Eloquent bridge
test_symfony_eloquent_bridge: bin/console \
							  vendor-bin/symfony/bin/phpunit \
							  remove_sf_cache refresh_mysql_db
	php bin/console eloquent:migrate:install --kernel=EloquentKernel

	vendor-bin/symfony/bin/phpunit -c phpunit_symfony_eloquent.xml.dist

test_symfony_doctrine_bridge_proxy_manager:	## Run the tests for the Symfony Doctrine bridge with Proxy Manager
test_symfony_doctrine_bridge_proxy_manager: bin/console \
											vendor-bin/proxy-manager/bin/phpunit \
											remove_sf_cache \
											refresh_mysql_db \
											refresh_phpcr \
											refresh_mongodb_db
	php bin/console doctrine:schema:create --kernel=DoctrineKernel

	vendor-bin/proxy-manager/bin/phpunit -c phpunit_symfony_proxy_manager_with_doctrine.xml.dist

test_symfony_eloquent_bridge_proxy_manager:	## Run the tests for the Symfony Eloquent bridge with Proxy Manager
test_symfony_eloquent_bridge_proxy_manager: bin/console \
											vendor-bin/proxy-manager/bin/phpunit \
											remove_sf_cache \
											refresh_mysql_db
	php bin/console eloquent:migrate:install --kernel=EloquentKernel

	vendor-bin/proxy-manager/bin/phpunit -c phpunit_symfony_proxy_manager_with_eloquent.xml.dist


##
## Code Style
##---------------------------------------------------------------------------

cs:             ## Run the CS Fixer
cs: remove_sf_cache	vendor-bin/php-cs-fixer/vendor
	$(PHP_CS_FIXER) fix


##
## Rules from files
##---------------------------------------------------------------------------

composer.lock: composer.json
	@echo compose.lock is not up to date.

vendor/phpunit: composer.lock
	composer install


vendor-bin/covers-validator/composer.lock: vendor-bin/covers-validator/composer.json
	@echo covers-validator composer.lock is not up to date

vendor-bin/covers-validator/vendor: vendor-bin/covers-validator/composer.lock
	composer bin covers-validator install


vendor-bin/php-cs-fixer/composer.lock: vendor-bin/php-cs-fixer/composer.json
	@echo php-cs-fixer composer.lock is not up to date.

vendor-bin/php-cs-fixer/vendor: vendor-bin/php-cs-fixer/composer.lock
	composer bin php-cs-fixer install


vendor-bin/doctrine/composer.lock: vendor-bin/doctrine/composer.json
	@echo vendor-bin/doctrine/composer.lock is not up to date.

vendor-bin/doctrine/bin/phpunit: vendor-bin/doctrine/composer.lock
	composer bin doctrine install


vendor-bin/doctrine_mongodb/composer.lock: vendor-bin/doctrine_mongodb/composer.json
	@echo vendor-bin/doctrine_mongodb/composer.lock is not up to date.

vendor-bin/doctrine_mongodb/bin/phpunit: vendor-bin/doctrine_mongodb/composer.lock
	composer bin doctrine_mongodb install


vendor-bin/doctrine_phpcr/composer.lock: vendor-bin/doctrine_phpcr/composer.json
	@echo vendor-bin/doctrine_phpcr/composer.lock is not up to date.

vendor-bin/doctrine_phpcr/bin/phpunit: vendor-bin/doctrine_phpcr/composer.lock
	composer bin doctrine_phpcr install

vendor-bin/doctrine_phpcr/bin/phpcrodm: vendor-bin/doctrine_phpcr/composer.lock
	composer bin doctrine_phpcr install


vendor-bin/eloquent/composer.lock: vendor-bin/eloquent/composer.json
	@echo vendor-bin/eloquent/composer.lock is not up to date.

vendor-bin/eloquent/bin/phpunit: vendor-bin/eloquent/composer.lock
	composer bin eloquent install


vendor-bin/symfony/composer.lock: vendor-bin/symfony/composer.json
	@echo vendor-bin/symfony/composer.lock is not up to date.

vendor-bin/symfony/bin/phpunit: vendor-bin/symfony/composer.lock
	composer bin symfony install --ignore-platform-reqs

bin/console: vendor-bin/symfony/composer.lock
	composer bin symfony install --ignore-platform-reqs


vendor-bin/proxy-manager/composer.lock: vendor-bin/proxy-manager/composer.json
	@echo vendor-bin/proxy-manager/composer.lock is not up to date.

vendor-bin/proxy-manager/bin/phpunit: vendor-bin/proxy-manager/composer.lock
	composer bin proxy-manager install
