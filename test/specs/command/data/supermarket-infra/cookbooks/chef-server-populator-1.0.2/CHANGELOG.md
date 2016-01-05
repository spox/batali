## v1.0.2
* Org recipe only included for solo run, since client run expects data
bag items.

## v1.0.0
* Updates to support Chef 12
* Removes support for Chef 11
* Adds support for organization creation in solo and client contexts
* Updates backup/restore recipes for new psql path and new table &
field names. (Not fully tested)
* Replaces many knife and psql commands with native chef-server-clt
management commands

## v0.4.0
* Allow for creation of clients, users, or both
* Store backup configuration in separate JSON file
* Provide proper retries to account for temporary server unavailability
* Include full server restart on restore from backup
* Provide 'latest' backup files along with named files
* Convert backup script from template to cookbook file
* Make service restarts more consistent

## v0.3.2
* Add client creation retries to stabilize initial bootstrap
* Updates to example bootstrap script
* Add support for backup/restore (thanks @luckymike!)

## v0.3.0
* Include chef-server dependency
* Update configuration overrides for chef-server
* Use `:endpoint` attribute for custom hostname/ip

## v0.2.0
* Provide distinct solo vs. client recipes
* Client recipe configures dna.json and uses ctl for reconfigure
