---
layout: post
title: "Command Line Reference"
categories: getting-started 
---


```bash
plank [options] file1 file2 ...
```

## General Options

| Option | Description |
|---|---|
| `lang` | Comma separated list of target language(s) for generating code. Values supported: `objc`, `flow`, `java`. Default: `objc` |
| `output_dir` | Specifies the directory where Plank will write generated files |
| `print_deps` | Displays schema dependencies for any schemas passed as arguments and then exits (i.e. for `pin.json` return `user.json`, `board.json`, and `image.json` separated by colons) |
| `indent` | Define a custom indentation width. Default "4" for Objective-C, Java and "2" for Flow |
| `no_recursive` | Only generates files passed in on the commandline (i.e. for `pin.json` only generate `Pin.m` and `Pin.h`) |
| `only_runtime` | Only generates runtime files and exits |
| `no_runtime` | Avoids generating runtime files |
| `help` | Displays usage documentation |
| `version` | Displays version |

## Objective-C 

| Option | Description |
|---|---|
| `objc_class_prefix` | Specifies a prefix to append to the beginning of all classes (i.e. `PIN` for `PINUser`) |


## Java
**Java support is experimental at this time**

| Option | Description |
|---|---|
| `java_package_name` | The package name to associate with generated Java sources. Example "--java_package_name=com.pinterest.models" |
