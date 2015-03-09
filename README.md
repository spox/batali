# Batali

Batali is a light weight cookbook resolver. It is currently
in an alpha state and should not be used with anything you
care about or love. There is a high chance it will burn it
all to the ground, and laugh.

## Usage

Provide a `Batali` file:

```ruby
Batali.define do
  source 'https://supermarket.chef.io'
  cookbook 'postgresql'
end
```

and then run:

```
$ batali update
```

in the same directory. It will destroy your `cookbooks` directory
by default.

_IT WILL DESTROY YOUR COOKBOOKS DIRECTORY BY DEFAULT_

## Commands

* `batali resolve` - Resolve dependencies and produce `batali.manifest`
* `batali install` - Install entries from the `batali.manifest`
* `batali update`  - Perform `resolve` and then `install`

## Features

### Origins

Currently supported "origins":

* RemoteSite
* Path
* Git

#### RemoteSite

This is simply a supermarket endpoint:

```ruby
source 'https://supermarket.chef.io'
```

Multiple endpoints can be provided by specifying multiple
`source` lines. They can also be named:

```ruby
source 'https://supermarket.chef.io', :name => 'opscode'
source 'https://cookbooks.example.com', :name => 'example'
```

##### Path

Paths are defined via cookbook entries:

```ruby
cookbook 'example', path: '/path/to/example'
```

##### Git

Git sources are defined via cookbook entries:

```ruby
cookbook 'example', git: 'git://git.example.com/example-repo.git', ref: 'master'
```

### Least Impact Updates

After a `batali.manifest` file has been generated, subsequent `resolve` requests
will update cookbook versions using a "least impact" approach. This means that
by default if the `Batali` file has not changed, running a `batali resolve` will
be a noop even if new versions of cookbooks may be available. This helps to reduce
unintended upgrades that may break things due to a required cookbook update. Allowing
a cookbook to be updated is done simply by adding it to the request:

```
$ batali resolve example
```

This will only update the version of the example cookbook, and any dependency cookbooks
that _must_ be updated to provide resolution. Multiple cookbooks can be listed:

```
$ batali resolve example ipsum lorem
```

or this feature can be disabled to allow everything to be updated to the latest
possible versions:

```
$ batali resolve --no-least-impact
```

### Light weight

One of the goals for batali was a being light weight resolver, in the same vein as
the [librarian][1] project. This means it does nothing more than manage cookbooks. This
includes dependency and constraint resolution, as well as providing a local installation
of assets defined within the generated manifest. It provides no extra features outside of
that scope.

### Multiple platform support

Batali does not rely on the [chef][2] gem to function. This removes any dependencies on
gems that may be incompatible outside the MRI platform.

### Isolated manifest files

Manifest files are fully isolated. The resolver does not need to perform any actions
for installing cookbooks defined within the manifest. This allows for easy transmission
and direct installation of a manifest without the requirement of re-pulling information
from sources.

# Info

* Repository: https://github.com/hw-labs/batali

[1]: https://rubygems.org/gems/librarian "A Framework for Bundlers"
[2]: https://rubygems.org/gems/chef "A systems integration framework"