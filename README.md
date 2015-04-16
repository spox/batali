# Batali

Batali is a light weight cookbook resolver. It is now in
a beta state, moving quickly towards a proper stable release.

## What is Batali?

Batali is a cookbook resolver. It's built to be light weight
but feature rich. Batali helps to manage your cookbooks and
stay out of your way.

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

You can make it not destroy your cookbooks directory by providing
a different path. A better idea is to not use the cookbooks directory.
Just ignore that sucker and let Batali do its thing.

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
be a noop, even if new versions of cookbooks may be available. This helps to reduce
unintended upgrades that may break things due to a required cookbook update. Allowing
a cookbook to be updated is done simply by adding it to the request:

```
$ batali resolve example
```

This will only update the version of the example cookbook, and any dependency cookbooks
that _must_ be updated to provide resolution. Dependency cookbooks that require an upgrade
based on constraints will attempt to upgrade with the _least impact possible_ by attempting
to satisfy constraints within the minimum version segement possible. For example, if our
Batali file contains the following:

```ruby
Batali.define do
  source 'https://example.com'
  cookbook 'soup'
end
```

and after resolving we have two cookbooks in our manifest:

```
soup <1.0.0>
salad <0.1.4>
```

Some time passes and a new version of `soup` is released, version 1.0.2. In that time
multiple new versions of the `salad` cookbook have been released, with new features and
with some breaking changes. For this example, lets assume available versions of the `salad`
cookbook are:

```
<0.1.4>
<0.1.6>
<0.1.8>
<0.2.0>
<0.2.2>
<0.3.0>
<1.0.0>
```

and the `soup` cookbook has updated its `salad` dependency:

```ruby
# soup metadata.rb
depends 'salad', '> 0.2'
```

Due to the behavior of existing solvers, we may expect the resolved manifest to include
`salad` at the latest possible version: `1.0.0`. This is a valid solution, since the
dependency is simply stating the constraint requires `salad` be _greater_ than `0.2` and
nothing more. However, this is a very large jump from what we currently have defined
within our manifest, and jumps a major and minor version. The possibility of breaking
changes being introduced is extremely high.

Since Batali has the **least impact** feature enabled by default, it will only upgrade
`salad` to the `0.2.2` version. This is due to the fact that the **least impact** feature
prefers the _latest_ cookbook available within the _closest_ version segement of the cookbook
version currently defined within the manifest. Since thew new `soup` dependency contraint
requires versions `> 0.2`, no `> 0.1` versions are acceptable. Batali then looks to the
next available segment `0.2` and attempts to use the latest version: `0.2.2`. This solves the
constraint, and is used for the new solution.

Multiple cookbooks can be listed for upgrade:

```
$ batali resolve example ipsum lorem
```

or this feature can be disabled to allow everything to be updated to the latest
possible versions:

```
$ batali resolve --no-least-impact
```

### Light weight

One of the goals for batali was being light weight resolver, in the same vein as
the [librarian][1] project. This means it does nothing more than manage local cookbooks. This
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

### Infrastructure manifests

Batali aims to solve the issue of full infrastructure resolution: resolving dependencies
from an infrastructure repository. Resolving a single dependency path will not provide
a correct resolution. This is because environments or run lists can provide extra constraints
that will result in unsolvable resolutions on individual nodes. In this case we want
to know what cookbooks are _allowed_ within a solution, and ensure all those cookbooks
are available. Batali provides infrastructure level manifests by setting the `infrastructure`
flag:

```
$ batali resolve --infrastructure
```

_NOTE: Depending on constraints defined within the Batali file, this can be a very large manifest_

#### Uploading infrastructure cookbooks

When the infrastructure cookbooks are installed locally, the cookbook directories will have
the version number as a suffix. This can cause a problem when attempting to run:

```
$ knife cookbook upload --all
```

due to knife using the directory name as the actual cookbook name. To get around this problem
the `upload` command can be used directly with the correct options enabled. These options must
be defined within the config file as the options are not accessible via CLI flags. Assuming
a `.chef/knife.rb` file exists:

```ruby
# .chef/knife.rb

versioned_cookbooks true
```

```
$ knife upload cookbooks
```

### Display outdated cookbooks

Want to see what cookbooks have newer versions available within the defined constraints? Use
the dry run option to see what upgrades are available without actually changing the manifest:

```
$ batali resolve --no-least-impact --dry-run
```

## Test Kitchen

Batali can be used with [Test Kitchen](https://github.com/test-kitchen/test-kitchen):

* https://github.com/hw-labs/batali-tk

## ChefSpec

Batali can be used with [ChefSpec](https://github.com/sethvargo/chefspec). Add the following
line to your `spec_helper.rb` file:

```ruby
require 'batali/chefspec'
```

# Info

* Repository: https://github.com/hw-labs/batali

[1]: https://rubygems.org/gems/librarian "A Framework for Bundlers"
[2]: https://rubygems.org/gems/chef "A systems integration framework"