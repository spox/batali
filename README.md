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

There is other cool stuff too, to be documented later. Currently
only site sources can be defined (no path, or git, or anything else).


# Info

* Repository: https://github.com/hw-labs/batali
