# Plank

Plank is a JSON schema based immutable model generator for iOS we created to achieve this. Plank is a command-line tool written in Swift that generates immutable Objective-C models.

## Introduction

## Features

*Immutable* — Model classes will be generated with immutability as a requirement. Each class will have “Builder” class to handle mutation.
*Type safe* — Based on the type information specified in the schema definition, each class will provide type validation and null reference checks to ensure model integrity.
*Schema-defined* — Model types should be defined in a language-independent format that’s easy to extend and well-known.

## Schemas

Plank schemas are based on JSON, a well-defined, extensible and language-independent specification. Defining schemas in JSON allowed us to avoid writing unnecessary parser code and opened up the possibility of generating code from the same type system used on the server.

Similar to a compiler, we translate these JSON schemas into an intermediate representation (IR) we refer to as the “Schema IR.” Once we have the Schema IR, we translate it to an Objective-C IR. This additional IR level is important, because while Plank generates Objective-C code today, it’s designed to support more languages in the future.

## Contributing

Pull requests for bug fixes and features welcomed.

## License

Copyright 2017 Pinterest, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
