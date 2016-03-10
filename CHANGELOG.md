# v0.4.4
* [fix] Explicit chef/rest require (#77)

# v0.4.2
* [fix] Loosen dependency constraints

# v0.4.0
* [feature] Add `supermarket` command for static repository generation

# v0.3.14
* [enhancement] Use threads when installing cookbooks (#72 thanks @sawanoboly!)

# v0.3.12
* [feature] Support multiple sources for single cookbook in infra-mode
* [fix] Make cache directory usage consistent in all commands

# v0.3.10
* [feature] Chef server manifest sync knife plugin

# v0.3.8
* [fix] Generate JSON properly under old implementations

# v0.3.6
* [task] Removed http cache usage due to support removal
* [fix] Fixed file system issues on windows (#62 and #63)
 * Thanks to @kenny-evitt and @webframp for helping to chase down the windows issues

# v0.3.4
* [fix] Open file as binary when storing compressed asset (#60 and #61 thanks @kenny-evitt!)

# v0.3.2
* [enhancement] Error on infrastructure resolution if full requirement list isn't available

# v0.3.0
* [enhancement] Properly restore BFile from serialized data
* [enhancement] Provide access to environment specific constraint usage

# v0.2.32
* [fix] Skip constraint merging when entry is non-site sourced
* [enhancement] Support dry run in infrastructure resolve
* [enhancement] Provide colorized diff on infrastructure manifest updates via resolve

# v0.2.30
* [fix] Run world pruner prior to manifest output
* [enhancement] Provider UI context when pruning world

# v0.2.28
* [fix] Properly install subdirectory when path defined on git source

# v0.2.26
* [feature] Add subdirectory support for git repository sources

# v0.2.24
* [enhancement] Add cache command for inspection and removal
* [fix] Automatically destroy and retry failed asset unpack
* [fix] Use relative path with metadata keyword

# v0.2.22
* [fix] Update chefspec integration to properly install cookbooks

# v0.2.20
* [fix] Use `config` for command merge when running update

# v0.2.18
* Add warning when unknown keywords used within Batali file

# v0.2.16
* Add `display` command for inspect manifest
* [fix] Update bogo-cli constraint to provide configuration merge fix

# v0.2.14
* Add support for using the Chef Server as a source

# v0.2.12
* Update home directory path generation to use `Dir.home`
* Detect resolution type from manifest files
* Add support for chefignore file (also allows `.chefignore`)
* Introduce automatic cookbook constraint detection

# v0.2.10
* Parse full metadata file on path sources to properly discover all deps (#26)
* Allow source to be optionally defined for Units
* Provide better handling when encountering Units with no possible solution
* Include `no_proxy` environment variable support

# v0.2.8
* Include missing infrastructure configuration flag on install command
* Default the cache directory to home directory to isolate users
* Add support for configuration file

# v0.2.6
* Add support for ChefSpec

# v0.2.4
* Fix caching support

# v0.2.2
* Add guard when switching resolution types (#14)
* Cache HTTP requests (#20)
* Prune cookbook results for infrastructure resolution (#21)
* Provide least impact behavior when resolving infrastructure (#19)

# v0.2.0
* Add proxy support (#18)
* Transition to "beta" state

# v0.1.22
* Add support for `metadata` keyword in Batali file
* Extract install path from merged config instead of only namespaced opts

# v0.1.20
* Reuse ui on `update` command when calling `resolve` and `install`

# v0.1.18
* Update restriction key from :to -> :source (#7)
* Show unit removals on single path resolution output
* Complete unit scoring implementation (#11)

# v0.1.16
* Include cookbook removals on resolve output
* Add initial infrastructure resolve output to show cookbooks + versions
* Update restrictions to use `:source` instead of `:to` for source reference

# v0.1.14
* Start adding debug and verbose output (#9)
* Update exception messages to provide more clarity

# v0.1.12
* Bug fix for multiple constraint arguments
* Provide consistent type for values that can be multiples within Batali file
* Get started on spec coverage

# v0.1.10
* Bug fix for Batali file parsing to provide expected format on processing

# v0.1.8
* Provide helpful exception message when source is not found
* Allow using default classes when building items
* Removing constant swapping in grimoire

# v0.1.6
* Bug fix for proper Batali file loading when single cookbook defined
* Bug fix for cookbook install when using path source (git as well)
* Add color coding to solution output on single path resolutions

# v0.1.4
* Bug fix for dependency parsing when using path type source

# v0.1.2
* Add support for git and path origins
* Cache assets from origins locally for reuse
* Add initial support for infrastructure resolution

# v0.1.0
* Initial release
