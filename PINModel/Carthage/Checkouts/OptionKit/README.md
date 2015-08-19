OptionKit - Option Parsing in Swift
=========

OptionKit is an OS X framework to parse basic command-line options in pure Swift. Currently,
it has the most basic functionality necessary, but will probably expand to include more
advanced features as the need arises.

## Usage

OptionKit currently supports three types of options:

* Short options, triggered by flags of type `-f`
* Long options, triggered by flags of type `--long-option`
* Mixed options, triggered by either type, such as `-v` or `--version`

An option can have zero or more required parameters. Parameters are restricted
in that they cannot begin with `-` or `--`, as they would be confused with triggers.

OptionKit's `OptionParser` class returns a `ParseData` type, which consists of:

* A dictionary of `Option` objects mapped to their (possibly empty) parameter list.
* A list of remaining arguments.

### Example

A simple, full example called `optionsTest.swift` might be:

```swift
#!/usr/bin/env xcrun swift -F /Library/Frameworks

import Foundation
import OptionKit

let opt1 = Option(trigger:.Mixed("e", "echo"))
let opt2 = Option(trigger:.Mixed("h", "help"))
let opt3 = Option(trigger:.Mixed("a", "allow-nothing"))
let opt4 = Option(trigger:.Mixed("b", "break-everything"))
let opt5 = Option(trigger:.Mixed("c", "counterstrike"))
let parser = OptionParser(definitions:[opt1, opt3, opt4, opt5])

let actualArguments = Array(Process.arguments[1..<Process.arguments.count])
let result = parser.parse(actualArguments)

switch result {
case .Success(let box):
    let (options, rest) = box.value
    if options[opt1] != nil {
        println("\(rest)")
    }

    if options[opt2] != nil {
      println(parser.helpStringForCommandName("optionTest"))
    }
    
case .Failure(let err):
   println(err)
}
```

The output would be:

```
~: ./optionTest.swift -e hello
[hello]
~: ./optionTest.swift --echo hello world
[hello, world]
~: ./optionTest.swift -h
usage: optionTest [-e|--echo] [-a|--allow-nothing] [-b|--break-everything]
                  [-c|--counterstrike] [-h|--help]

~: ./optionTest.swift --help
usage: optionTest [-e|--echo] [-a|--allow-nothing] [-b|--break-everything]
                  [-c|--counterstrike] [-h|--help]

~: ./optionTest.swift -d
Invalid option: -d
```

## Installation

Minimum system requirements:

* Xcode 6.3β4
* OS X Yosemite 10.10

Steps:

1. Clone this github repository, and build the project.
1. Run the tests, just for sanity. They should all pass.
1. Copy `OptionKit.framework` from the `DerivedData` directory to `/Library/Frameworks`
  (this will require `sudo` access)

OptionKit should now be available for use from a command line script. The shebang needs
to read:

```swift
#!/usr/bin/env xcrun swift -F /Library/Frameworks
```
This is because the Swift compiler, unlike Clang, doesn't automatically pick up frameworks in
`/Library/Frameworks`.

## Including OptionKit in Other Libraries

Use [Carthage](https://github.com/Carthage/Carthage). OptionKit uses semantic versioning, so
the corresponding Cartfile line should be:

```
github "nomothetis/OptionKit" ~> 0.2.0
```

### To Do

* Add support for sub-parsers.
* Make help string include per-option help.
