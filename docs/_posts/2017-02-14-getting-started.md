---
layout: post
title: "Getting Started"
---

**Tutorial**
In this tutorial we’re going to create a very simple schema that should provide enough guidance to write complex schemas. Some of the contents will be related to the iOS project but the actual schemas are platform independent.

**Creating a new schema file**
Create a new file there called “example_model.json”

**Start writing your schema.**

Schemas are a JSON document. We’ll start with a schema that is simple adaptation of the one declared at the beginning of this [document](https://docs.google.com/document/d/12gCJ-lTiwmOiTjMmVxJIMzMCAimFEiUQORKserTI68c/edit#heading=h.3qktp9j6yx33)


    {
        "id": "schemas/example_model.json",
        "title": "example_model",
        "description" : "Schema definition of my example model",
        "$schema": "http://json-schema.org/schema#",
        "type": "object",
        "properties": { "id" : { "type": "string" },},
        "required": [] 
    }


**Generate your model classes**
`plank [path to schema]` 
To generate the models, run this command:
`plank schemas/example_model.json` 
The generator will not only generate this class but it will generate its superclass (if defined) and any other class that is referenced by a [JSON Pointer](https://docs.google.com/document/d/12gCJ-lTiwmOiTjMmVxJIMzMCAimFEiUQORKserTI68c/edit#heading=h.ykiwozj6u36d). The classes will be available for you in the current working directory.

Exercises for the reader

- Explore different property types (integer, number, boolean, URI strings, Datetime strings, arrays, objects)
- Create another schema (another_example_schema.json) and reference it in your original schema with a JSON Pointer
- Add collection properties such as objects and arrays and specify their item types. For extra credit, specify the item type as a JSON Pointer (self-referential pointers work as well!).
## Future work
- Support for the definitions key in JSON-Schema. Definitions is a lighter form of declaring small schemas and can also be referenced with a JSON Pointer.
- Documentation Generation.
- Proper error reporting and logging for invalid schemas.
- Generate from API responses rather than local handwritten schemas.
- Make models available as a separate Cocoapod to automate generation and integration.
