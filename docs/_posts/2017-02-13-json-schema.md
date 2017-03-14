---
layout: post
title: "JSON Schema"
categories: Reference
---

JSON Schema is a powerful tool for validating the structure of JSON data. In practice, these schemas can be used to create validators, code generators and other useful tools to handle complex and/or tedious issues. There is a great online overview of JSON-Schema and its specifics here: [http://spacetelescope.github.io/understanding-json-schema/#](http://spacetelescope.github.io/understanding-json-schema/#). For the purposes of this document we will only be concerned with version 4 of JSON-Schema.

## JSON Schema Basics

Here is a simple schema and overview of the fields listed.
{% highlight json %}
    {
        "id": "user.json",
        "extends": "base_model.json",
        "title": "user",
        "description" : "Schema definition of a User",
        "$schema": "http://json-schema.org/schema#",
        "type": "object",
        "properties": {
            "id" : { "type": "string" }
        },
        "required": []
    }
{% endhighlight %}

| Field name | Description |
| --- | --- |
| `id` (String)                      | The id property identifies where this resource can be found. This can either be a relative or absolute path. In addition, schemas that are accessed remotely can be accessed by specifying the correct URI. This value will become more important when we discuss JSON Pointers below. |
| `extends` (String)                      | The extends key is a JSON pointer (`$ref`)  that refers to a parent schema |
| `title` (String)                   | Title is used to identify the name of the object. The convention we use is all lowercase with underscores (“_”) to separate words (i.e. “offer_summary”).                                                                                                                              |
| `description` (String)             | Description is a helpful place to specify more detail about the current model object or property.                                                                                                                                                                                      |
| `$schema` (String, URI formatted)  | This is a URI to the json-schema version this document is based on. This will be the default schema URI for now: "[http://json-schema.org/schema#](http://json-schema.org/schema#)"                                                                                                    |
| `type` (String)                    | Specifies the type, currently this is always “object” when declared outside of the properties map. Valid types are “string”, “boolean”, “number”, “integer”, “array”, “object”.                                                                                                |
| `properties` (Map<string, object>) | Properties are where most of your editing will be focused. This area allows us to specify the property names (as the key) as well as their expected type.                                                                                                                              |
| `required`                         | List of property names that are required to be present in the JSON response. This is currently unused but eventually could be utilized to provide tighter validation of schema responses.                                                                                              |


## Property fields
Properties are where most of your editing will be focused. This area allows us to specify the fields that are available on this model. The properties declaration is a map from the property name to an object that describes the property.

The keys should follow the same naming conventions as title field (lowercase, underscore separated). The value will be an object that can be one of the types specified earlier or a reference to another JSON-schema file (via JSON Pointer `$ref` ).

In addition, there is syntax for providing concrete subtypes such as dates, URIs, and emails as shown below. A full list can be seen under the JSON-Schema type-specific documentation [here](http://spacetelescope.github.io/understanding-json-schema/reference/type.html).


### Types of Properties

| Type                | Description |
| :--- | :--- |
| String                              | |
| Boolean                             | |
| Integer                             | |
| Number                              | |
| Date-time Property (String variant) | |
| String Property                     | |
| URI Property (String variant)       | |
| JSON Pointer Property (`$ref`)        | |
| Array Property                      | |
| Array Property with Item types      | |
| Object Property                     | |
| Object Property with item types     | |
| Algebraic Data Type (`oneOf`)       | |





### Examples

#### String Property
{% highlight json %}
{
    "about" : { "type" : "string" }
}
{% endhighlight %}


#### String Enum
{% highlight json %}
{
  "email_interval" : {
    "type" : "string",
    "enum": [
        { "default" : "unset", "description" : "unset" },
        { "default" : "immediate", "description" : "immediate" },
        { "default" : "daily", "description" : "daily" }
    ],
    "default" : "unset"
}
{% endhighlight %}


#### Boolean
{% highlight json %}
{
    "blocked_by_me" : { "type" : "boolean" }
}
{% endhighlight %}

#### Integer
{% highlight json %}
{
    "blocked_by_me" : { "type" : "boolean"}
}
{% endhighlight %}

#### Integer Enum
{% highlight json %}
{
    "in_stock" : {
        "type": "integer",
        "enum": [
            { "default" : -1, "description" : "unknown" },
            { "default" : 0, "description" : "out_of_stock" },
            { "default" : 1, "description" : "in_stock" }
        ]
    }
}
{% endhighlight %}

#### Date-Time (String variant)
{% highlight json %}
{
    "created_at" : { "type" : "string" , "format" : "date-time"}
}
{% endhighlight %}

#### URI (String variant)
{% highlight json %}
{
    "image_large_url" : { "type" : "string", "format": "uri" }
}
{% endhighlight %}

#### Schema (another model referenced via JSON Pointer)
{% highlight json %}
{
    "verified_identity" : { "$ref" : "verified_identity.json" }
}
{% endhighlight %}

#### Array Property

- Simple Array
{% highlight json %}
{
    "pin_thumbnail_urls" : { "type": "array" }
}
{% endhighlight %}

- Array with item type (Array<URI>)
{% highlight json %}
{
    "pin_thumbnail_urls" : {
            "type": "array",
            "items": {
                 "type": "string",
                 "format": "uri"
             }
    }
}
{% endhighlight %}

#### Map (Object)
- Simple Map
{% highlight json %}
{
    "some_map" : { "type": "object" }
}
{% endhighlight %}

- Map with value types

{% highlight json %}
{
    "some_map" : {
        "type": "object",
        “additionalProperties”: { $ref : “user.json” }
    }
}
{% endhighlight %}


#### Algebraic Data Type (ADT or `oneOf`)
{% highlight json %}
{
	"items": {
		"oneOf" : [
			{ "$ref" : "pin.json" },
			{ "$ref" : "board.json" },
			{ "$ref" : "interest.json" },
			{ "$ref" : "user.json" }
		]
	}
}
{% endhighlight %}


## Appendix

### JSON Pointer

Most of these property declarations should be straightforward to understand with the exception of JSON Pointer. This is a specific syntax that is used to reference the location of other JSON files.
The key for a JSON pointer is “$ref” and the value is a path relative to the base location which was specified by the “id” key.

Here’s an example of how the pointers destination is resolved.

1. The schema declares an `id` property:
2. "id": "[http://foo.bar/schemas/address.json](http://foo.bar/schemas/address.json)"
3. There is a property defined with a JSON pointer as its value.
4. `“some_property_name” : { "$ref": "person.json" }`
5. When the pointers destination is resolved, it will be:
6. http://foo.bar/schemas/person.json

## WIP Plank schema definition

{% highlight json %}
{
    "id": "http://json-schema.org/draft-04/schema#",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "",
    "definitions": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$ref": "#" }
        },
        "simpleTypes": {
            "enum": [ "array", "boolean", "integer", "number", "object", "string" ]
        },
        "stringArray": {
            "type": "array",
            "items": { "type": "string" },
            "minItems": 1,
            "uniqueItems": true
        }
    },
    "type": "object",
    "properties": {
        "id": {
            "type": "string",
            "format": "uri"
        },
        "title": {
            "type": "string"
        },
        "description": {
            "type": "string"
        },
		"extends": {
			"type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
		},
        "$schema": {
            "type": "string",
            "format": "uri"
        },
        "type": {
            { "$ref": "#/definitions/simpleTypes" },
        },
        "default": {},
        "additionalItems": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "items": {
            "anyOf": [
                { "$ref": "#" },
                { "$ref": "#/definitions/schemaArray" }
            ],
            "default": {}
        },
        "additionalProperties": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "properties": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "enum": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": true
        },
        "required": { "$ref": "#/definitions/stringArray" },
        "oneOf": { "$ref": "#/definitions/schemaArray" },
    },
    "default": {}
}

{% endhighlight %}

