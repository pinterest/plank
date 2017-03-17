---
layout: post
title: "JSON Pointers"
categories: json-reference
---

A JSON Pointer is a specific property syntax used to reference the location of other JSON files. The property key for a JSON pointer is `$ref` and the value is a path relative to the base location which was specified by the `id` key.

Here’s an example of how the pointers destination is resolved:

1. The schema declares an `id` property:
2. "id": "[http://foo.bar/schemas/address.json](http://foo.bar/schemas/address.json)"
3. There is a property defined with a JSON pointer as its value.
4. `“some_property_name” : { "$ref": "person.json" }`
5. When the pointers destination is resolved, it will be:
6. http://foo.bar/schemas/person.json
