# Arcanist Owners

[![Build Status](https://travis-ci.org/pinterest/arcanist-owners.svg)](https://travis-ci.org/pinterest/arcanist-owners)

This is an [Arcanist][] extension that displays file ownership information.
It is implemented as an `arc owners` command:

    owners [path ...]
        Supports: git, hg
        Display ownership information for a list of files.

        Without paths, the files changed in your local working copy will
        be used.

```
$ arc owners README.md
Arcanist Extensions (jparise)
  README.md
```

This is similar to the built-in `arc cover` command, but instead of inferring
likely owners based on "blame" statistics, `arc owners` uses the ownership
definitions specified in [Phabricator's Owners application][phab-owners].

It's possible that `arc cover` could evolve to the point where `arc owners`
becomes redundant. [T2443](https://secure.phabricator.com/T2443) tracks
progress in that direction.

## Installation

In short, you'll need to add this repository to your local machine and tell
Arcanist to load the extension. You either can do this globally or on a
per-project basis.

## Global Installation

Arcanist can load modules from an absolute path, but because it also searches
for modules one level up from itself on the filesystem, it's convenient to
clone this repository at the same level as `arcanist` and `libphutil`.

```
$ git clone https://github.com/pinterest/arcanist-owners.git
$ ls
arcanist
arcanist-owners
libphutil
```

Then, tell Arcanist to load the module by editing `~/.arcconfig` (or
`/etc/arcconfig`):

```json
{
  "load": ["arcanist-owners"]
}
```

## Project Installation

You can also load `arcanist-owners` on a per-project basis. In that case,
using a [git submodule](https://git-scm.com/docs/git-submodule) is probably
the most convenient approach.

```
$ git submodule add https://github.com/pinterest/arcanist-owners.git .arcanist-owners
$ git submodule update --init
```

Then, enable the module in your project-level `.arcconfig` file:

```json
{
  "load": [".arcanist-owners"]
}
```

[Arcanist]: https://secure.phabricator.com/book/phabricator/article/arcanist/
[phab-owners]: https://secure.phabricator.com/book/phabricator/article/owners/
