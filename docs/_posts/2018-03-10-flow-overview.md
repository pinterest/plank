---
layout: post
title: "Overview"
categories: flow-reference
---

#### JSON Schema to Flow type mapping

| Schema Property Type                | Flow Type                                               |
| :--- | :--- |
| Boolean                             | `boolean`                                                     |
| Integer                             | `number`                                                      |
| Number                              | `number`                                                         |
| String Property                     | `string` |
| Date-time Property (String variant) | `PlankDate`                                                         |
| URI Property (String variant)       | `PlankURI`                                                          |
| JSON Pointer Property (`$ref`)        | ModelType                                                      |
| Array Property                      | `Array<*>`                                                        |
| Array Property with Item types      | `Array<ModelType>`  |
| Object Property                     | `{}`                         |
| Object Property with item types     | `{ +[string]: ModelType }`                          |
| Algebraic Data Type (`oneOf`)       | `ModelOne | ModelTwo` |

## Example
For this example, the following schema definition of an extensive representation of a Pin type as well as the generated Flow type definition.

#### Pin Schema 

```json
{
    "id": "pin.json",
    "title": "pin",
    "description" : "Schema definition of Pinterest Pin",
    "$schema": "http://json-schema.org/schema#",
    "type": "object",
    "properties": {
		"id" : { "type": "string" },
		"link" : {
			"type": "string",
			"format": "uri"
		},
		"url" : {
			"type": "string",
			"format": "uri"
		},
		"creator": {
			"type": "object",
			"additionalProperties": { "$ref": "user.json" }
		},
		"board": { "$ref": "board.json" },
		"created_at" : {
			"type": "string",
			"format": "date-time"
		},
		"note" : { "type": "string" },
		"color" : { "type": "string" },
		"counts": {
			"type": "object",
			"additionalProperties": { "type": "integer" }
		},
		"media": {
			"type": "object",
			"additionalProperties": { "type": "string" }
		},
		"attribution": {
			"type": "object",
			"additionalProperties": { "type": "string" }
		},
		"description" : { "type": "string" },
		"image": { "$ref": "image.json" }
	},
    "required": []
}
```

#### Flow

```js
import type { PlankDate, PlankURI } from "./runtime.flow.js";
import type BoardType from "./BoardType.js";
import type ImageType from "./ImageType.js";
import type UserType from "./UserType.js";

export type PinType = $Shape<{|
    +note?: string | null,
    +media?: { [string]: string } | null,
    +counts?: { [string]: number } /* Integer */ | null,
    +descriptionText?: string | null,
    +creator?: { [string]: UserType } | null,
    +attribution?: { [string]: string } | null,
    +board?: BoardType | null,
    +color?: string | null,
    +link?: PlankDate | null,
    +identifier?: string | null,
    +image?: ImageType | null,
    +createdAt?: PlankDate | null,
    +url?: PlankDate | null,
|}> & {
    id: string
};
```

## Implementation Details 

### Type alias
For every plank type an exported Flow type alias with the name `TitleType` will be created.

### Property variance (read-only)
Currently all properties are defined as covariant (read-only), declared by the plus symbol in front of the property name.

### Optional properties
As it's currently not possible to know for sure, that properties are included within the API response we declare the properties as optional. Furthermore, if the property is included in the API response we don't know for sure if a valid value or null was received. Therefore the type definition of a property is always declared as optional.

### Primitive type properties
For types like integer or strings, equivalent primitive types like number and string are used.

### Object as maps properties
For object types that act like a map, like the `counts` property from above, we use a special kind of property, called an ["indexer property"](https://flow.org/en/docs/types/objects/#toc-objects-as-maps).

### Format type properties
For specific format types, we are providing pre-defined types which are defined in a specific runtime file. In case of the `date` and `uri` type the representation is just a string for now:

```js
...
export type PlankDate = string;
export type PlankURI = string;
...
```

### Reference properties
If references to other types are defined within the PDT, the referenced type will be imported and the property will be annotated with the reference type.

### Enum and ADT properties
We also have support for enums and ADTs, which are not present in the example above. Examples for both of them would look like the following:

#### ADTs

##### PDT
```json
...
"attribution": {
  "oneOf": [
    { "$ref": "image.json" },
    { "$ref": "board.json" }
  ]
},
...
```

##### Flow
```js
...
export type PinAttributionType = ImageType | BoardType;
...

export type PinType = $Shape<{|
  +attribution?: PinAttributionType | null,
  ...
|}> ...
```

#### Enums

##### PDT
```json
...
"status" : {
  "type": "string",
  "enum": [
      { "default" : "unknown", "description" : "unknown" },
      { "default" : "new", "description" : "new" },
      { "default" : "accepted", "description" : "accepted" },
      { "default" : "denied", "description" : "denied" },
      { "default" : "pending_approval", "description" : "pending_approval" },
      { "default" : "contact_request_not_approved", "description": "contact_request_not_approved" }
  ],
  "default" : "unknown"
},
"availability" : {
  "type": "integer",
  "enum": [
      { "default" : 1, "description" : "in_stock" },
      { "default" : 2, "description" : "out_of_stock" },
      { "default" : 3, "description" : "preorder" },
      { "default" : 4, "description" : "unavailable" }
  ]
},
...
```

##### Flow

```js
export type PinAvailabilityType =
    | 1 /* in_stock */
    | 2 /* out_of_stock */
    | 3 /* preorder */
    | 4; /* unavailable */
...
export type PinType = $Shape<{|
  +status?: PinStatusType | null,
  +availability?: PinAvailabilityType | null,
  ...
|}> ...
```

