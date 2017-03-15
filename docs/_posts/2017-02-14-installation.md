---
layout: post
title: "Installation"
categories: ["Getting Started"]
---

If you already have Plank installed, jump to the [tutorial](https://pinterest.github.io/plank/2017/02/14/tutorial.html).

## macOS

The easiest way to install Plank is through [Homebrew](https://brew.sh/):

{% highlight bash %}
$ brew install pinterest/tap/plank
{% endhighlight %}

## Linux (via Docker)

Plank supports building in Ubuntu Linux via Docker. The Dockerfile in the repository
will fetch the most recent release of plank and build dependencies including
the Swift snapshot.

{% highlight bash %}
$ docker build -t plank .
{% endhighlight %}

## Build from source
Plank is built using the [Swift Package Manager](https://swift.org/package-manager/). Although you'll be able to build Plank using `swift build` directly, for distribution of the binary we'd recommend using the commands in the Makefile since they will pass the necessary flags to bundle the Swift runtime.

{% highlight bash %}
$ make archive
{% endhighlight %}

## Testing Install

Test that Plank installed correctly by running the version flag:

{% highlight bash %}
$ plank --version
{% endhighlight %}

# Usage

Generate a schema file (`user.json`) using Plank using the format `plank [options] file1 file2 file3 ...`
{% highlight bash %}
$ plank user.json
{% endhighlight %}

This will generate files (User.h, User.m) in the current directory

Generate a schema file (`user.json`) using Plank.
{% highlight bash %}
$ ls
User.h User.m
{% endhighlight %}

There are a couple of options that can be specified with your invocation of
plank.

| Option | Description |
|---|---|
| `output_dir` | Specifies the directory where Plank will write generated files |
| `objc_class_prefix` | Specifies a prefix to append to the beginning of all classes (i.e. `PIN` for `PINUser`) |
| `help` | Displays usage documentation |

## Next Steps

To get a taste on how to use Plank in your project, check out the [tutorial](https://pinterest.github.io/plank/2017/02/14/tutorial.html).
