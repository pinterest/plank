---
layout: post
title: "Installation"
categories: getting-started 
---

If you already have Plank installed, jump to the [tutorial](/plank/docs/getting-started/tutorial.html).

## macOS

The easiest way to install Plank is through [Homebrew](https://brew.sh/):

<pre><code class="bash">$ brew install plank
</code></pre>

## Linux (via Docker)

Plank supports building in Ubuntu Linux via Docker. The Dockerfile in the repository
will fetch the most recent release of plank and build dependencies including
the Swift snapshot.

<pre><code class="bash">$ docker build -t plank .
</code></pre>

## Build from source
Plank is built using the [Swift Package Manager](https://swift.org/package-manager/). Although you'll be able to build Plank using `swift build` directly, for distribution of the binary we'd recommend using the commands in the Makefile since they will pass the necessary flags to bundle the Swift runtime.

<pre><code class="bash">$ make archive
</code></pre>

## Testing Install

Test that Plank installed correctly by running it with `--version`:

<pre><code class="bash">$ plank --version
</code></pre>

# Usage

Generate a schema file (`user.json`) using Plank using the format `plank [options] file1 file2 file3 ...`
<pre><code class="bash">$ plank user.json
</code></pre>

This will generate files (User.h, User.m) in the current directory

Generate a schema file (`user.json`) using Plank.
<pre><code class="bash">$ ls
User.h User.m
</code></pre>

There are a number of options that can be specified with your invocation of
plank. The [command line reference](/plank/docs/getting-started/command-line-reference.html) describes the general and language specific options available.

## Next Steps

To get a taste on how to use Plank in your project, check out the [tutorial](/plank/docs/getting-started/tutorial.html).
