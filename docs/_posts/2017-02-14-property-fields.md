---
layout: post
title: "Property Fields"
categories: json-reference
---

Properties are where most of your editing will be focused. This area allows us to specify the fields that are available on this model. The properties declaration is a map from the property name to an object that describes the property.

The keys should follow the same naming conventions as title field (lowercase, underscore separated). The value will be an object that can be one of the types specified earlier or a reference to another JSON-schema file (via JSON Pointer `$ref` ).

In addition, there is syntax for providing concrete subtypes such as dates, URIs, and emails as shown below. A full list can be seen under the JSON-Schema type-specific documentation [here](http://spacetelescope.github.io/understanding-json-schema/reference/type.html).


### Types of Properties

| Type                |
| :--- |
| String                              |
| Boolean                             |
| Integer                             |
| Number                              |
| Date-time Property (String variant) |
| String Property                     |
| URI Property (String variant)       |
| JSON Pointer Property (`$ref`)        |
| Array Property                      |
| Array Property with Item types      |
| Object Property                     |
| Object Property with item types     |
| Algebraic Data Type (`oneOf`)       |

### Examples

#### String Property
<pre><code class="json">{
    "about" : { "type" : "string" }
}
</code></pre>


#### String Enum
<pre><code class="json">{
  "email_interval" : {
    "type" : "string",
    "enum": [
        { "default" : "unset", "description" : "unset" },
        { "default" : "immediate", "description" : "immediate" },
        { "default" : "daily", "description" : "daily" }
    ],
    "default" : "unset"
}
</code></pre>


#### Boolean
<pre><code class="json">{
    "blocked_by_me" : { "type" : "boolean" }
}
</code></pre>

#### Integer
<pre><code class="json">{
    "blocked_by_me" : { "type" : "boolean"}
}
</code></pre>

#### Integer Enum
<pre><code class="json">{
    "in_stock" : {
        "type": "integer",
        "enum": [
            { "default" : -1, "description" : "unknown" },
            { "default" : 0, "description" : "out_of_stock" },
            { "default" : 1, "description" : "in_stock" }
        ]
    }
}
</code></pre>

#### Date-Time (String variant)
<pre><code class="json">{
    "created_at" : { "type" : "string" , "format" : "date-time"}
}
</code></pre>

#### URI (String variant)
<pre><code class="json">{
    "image_large_url" : { "type" : "string", "format": "uri" }
}
</code></pre>

#### Schema (another model referenced via JSON Pointer)
<pre><code class="json">{
    "verified_identity" : { "$ref" : "verified_identity.json" }
}
</code></pre>

#### Array Property

- Simple Array
<pre><code class="json">{
    "pin_thumbnail_urls" : { "type": "array" }
}
</code></pre>

- Array with item type (Array<URI>)
<pre><code class="json">{
    "pin_thumbnail_urls" : {
            "type": "array",
            "items": {
                 "type": "string",
                 "format": "uri"
             }
    }
}
</code></pre>

#### Map (Object)
- Simple Map
<pre><code class="json">{
    "some_map" : { "type": "object" }
}
</code></pre>

- Map with value types

<pre><code class="json">{
    "some_map" : {
        "type": "object",
        “additionalProperties”: { $ref : “user.json” }
    }
}
</code></pre>


#### Algebraic Data Type (ADT or `oneOf`)
<pre><code class="json">{
	"items": {
		"oneOf" : [
			{ "$ref" : "pin.json" },
			{ "$ref" : "board.json" },
			{ "$ref" : "interest.json" },
			{ "$ref" : "user.json" }
		]
	}
}
</code></pre>
