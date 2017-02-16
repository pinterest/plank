---
layout: default
---

# Plank

## Generate immutable models from JSON Schemas

Plank lets you generate model classes for you apps from schema files via the command line. The model schema definitions are represented in the json-schema v4 format.

## Immutable

Model classes will be generated with Immutability as a requirement. Each class will have "Builder" classes that will aid in mutation.

## Type Safe

Based on the type information specified in the schema definition, each class will provide type validation and null reference checks to ensure model integrity.

## Custom Validation

Each property can specify a set of parameters that will be used for validation. Examples of these properties are defined in the json-schema v4 specification.