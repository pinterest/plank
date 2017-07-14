---
layout: post
title: "Overview"
categories: json-reference
---

JSON Schema is a powerful tool for validating the structure of JSON data. In practice, these schemas can be used to create validators, code generators and other useful tools to handle complex and/or tedious issues. There is a great online overview of JSON-Schema and its specifics here: [http://spacetelescope.github.io/understanding-json-schema/#](http://spacetelescope.github.io/understanding-json-schema/#). For the purposes of this document we will only be concerned with version 4 of JSON-Schema.

## JSON Schema Basics

Here is a simple schema and overview of the fields listed.
<pre><code class="json">{
    "id": "user.json",
    "extends": "base_model.json",
    "title": "user",
    "description" : "Schema definition of a User",
    "$schema": "http://json-schema.org/schema#",
    "type": "object",
    "properties": {
        "id" : { "type": "string" }
    },
    "required": ["id"]
}
</code></pre>

| Field name | Description |
| --- | --- |
| `id` (String)                      | The id property identifies where this resource can be found. This can either be a relative or absolute path. In addition, schemas that are accessed remotely can be accessed by specifying the correct URI. This value will become more important when we discuss JSON Pointers below. |
| `extends` (String)                      | The extends key is a JSON pointer (`$ref`)  that refers to a parent schema |
| `title` (String)                   | Title is used to identify the name of the object. The convention we use is all lowercase with underscores (“_”) to separate words (i.e. “offer_summary”).                                                                                                                              |
| `description` (String)             | Description is a helpful place to specify more detail about the current model object or property.                                                                                                                                                                                      |
| `$schema` (String, URI formatted)  | This is a URI to the json-schema version this document is based on. This will be the default schema URI for now: "[http://json-schema.org/schema#](http://json-schema.org/schema#)"                                                                                                    |
| `type` (String)                    | Specifies the type, currently this is always “object” when declared outside of the properties map. Valid types are “string”, “boolean”, “number”, “integer”, “array”, “object”.                                                                                                |
| `properties` (Map<string, object>) | Properties are where most of your editing will be focused. This area allows us to specify the property names (as the key) as well as their expected type.                                                                                                                              |
| `required` (List<string>)                         | List of property names that are required to be present in the JSON response. This will be used to to specify nullability of items in `properties`.                                                                                              |
