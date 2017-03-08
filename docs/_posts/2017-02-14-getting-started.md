---
layout: post
title: "Getting Started"
---

If you already have Plank installed, jump to the [tutorial](https://pinterest.github.io/plank/2017/02/14/tutorial.html).

# Installation
## macOS

The easiest way to install Plank is through [Homebrew](https://brew.sh/):

{% highlight bash %}
$ brew install plank
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

## Next Steps

To get a taste on how to use Plank in your project, check out the [tutorial](https://pinterest.github.io/plank/2017/02/14/tutorial.html).
