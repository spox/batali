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
