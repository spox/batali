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
