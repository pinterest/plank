---
layout: default
---

# Plank

[Plank](https://github.com/pinterest/plank/) is a command-line code generation tool. The goal of this project is to generate model classes for Objective-C (iOS) initially and then expand to Java (Android) in the future. The model schema definitions are represented in the json-schema v4 format.
**Goals of the model classes**

- **Immutability** : Model classes will be generated with Immutability as a requirement. Each class will have "Builder" classes that will aid in mutation.
- **Type** **Safety** : Based on the type information specified in the schema definition, each class will provide type validation and null reference checks to ensure model integrity.
- **Custom Validation** : Each property can specify a set of parameters that will be used for validation. Examples of these properties are defined in the json-schema v4 specification.
## Creating a new Schema