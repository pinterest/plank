---
layout: post
title: "Overview"
categories: java-reference
---

#### JSON Schema to Java type mapping

| Schema Property Type | Java Type |
| :--- | :--- |
| String | `String` |
| Boolean | `Boolean` |
| Integer | `Integer` |
| Number | `Double` |
| Date-time Property (String variant) | `java.util.Date` |
| URI Property (String variant) | `String` |
| JSON Pointer Property (`$ref`) | ModelType |
| Array Property | `List<Object>` |
| Array Property with Item types | `List<ModelType>` |
| Set Property (unique array) | `Set<Object>` |
| Set Property (unique array) with items | `Set<ModelType>` |
| Object Property | `Map<String, Object>` |
| Object Property with item types | `Map<String, ModelType>`  |
| Object Property with primitive item type | `Map<String, Integer>`, `Map<String, Float>`, `Map<String, Boolean>`, `Map<String, String>` |
| Algebraic Data Type (ADT)(oneOf)   | ADT Class (ModelType + Property name)|
| Nullable Property | `@Nullable T` |
| Integer Enum | `@IntDef` |
| String Enum | `@StringDef` |

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
        "image": { "$ref": "image.json" },
        "tags": {
            "type": "array",
            "items": { "type": "object" }
        },
        "visual_search_attrs": {
            "type": "object"
        },
        "attribution_objects": {
            "type": "array",
            "items": {
                "oneOf": [{
                    "$ref": "board.json"
                }, {
                "$ref": "user.json"
                }]
            }
        },
        "in_stock" : {
            "type": "integer",
            "enum": [
                { "default" : -1, "description" : "unknown" },
                { "default" : 0, "description" : "out_of_stock" },
                { "default" : 1, "description" : "in_stock" }
            ]
        }
    },
    "required": ["id", "created_at", "creator"]
}
```

#### Java

```java
@AutoValue
public abstract class Pin {
    public static final int UNKNOWN = -1;
    public static final int OUT_OF_STOCK = 0;
    public static final int IN_STOCK = 1;
    @IntDef({UNKNOWN, OUT_OF_STOCK, IN_STOCK})
    @Retention(RetentionPolicy.SOURCE)
    public @interface PinInStock {}

    public abstract @SerializedName("attribution") @Nullable Map<String, String> attribution();
    public abstract @SerializedName("attribution_objects") @Nullable List<PinAttributionObjects> attributionObjects();
    public abstract @SerializedName("board") @Nullable Board board();
    public abstract @SerializedName("color") @Nullable String color();
    public abstract @SerializedName("counts") @Nullable Map<String, Integer> counts();
    public abstract @SerializedName("created_at") Date createdAt();
    public abstract @SerializedName("creator") Map<String, User> creator();
    public abstract @SerializedName("description") @Nullable String descriptionText();
    public abstract @SerializedName("id") String identifier();
    public abstract @SerializedName("image") @Nullable Image image();
    public abstract @SerializedName("in_stock") @Nullable @PinInStock int inStock();
    public abstract @SerializedName("link") @Nullable String link();
    public abstract @SerializedName("media") @Nullable Map<String, String> media();
    public abstract @SerializedName("note") @Nullable String note();
    public abstract @SerializedName("tags") @Nullable List<Map<String, Object>> tags();
    public abstract @SerializedName("url") @Nullable String url();
    public abstract @SerializedName("visual_search_attrs") @Nullable Map<String, Object> visualSearchAttrs();
    public static Builder builder() {
        return new AutoValue_Pin.Builder();
    }
    abstract Builder toBuilder();
    public static TypeAdapter<Pin> jsonAdapter(Gson gson) {
        return new AutoValue_Pin.GsonTypeAdapter(gson);
    }
    @AutoValue.Builder
    public abstract static class Builder {
        public abstract Builder setAttribution(@Nullable Map<String, String> value);
        public abstract Builder setAttributionObjects(@Nullable List<PinAttributionObjects> value);
        public abstract Builder setBoard(@Nullable Board value);
        public abstract Builder setColor(@Nullable String value);
        public abstract Builder setCounts(@Nullable Map<String, Integer> value);
        public abstract Builder setCreatedAt(Date value);
        public abstract Builder setCreator(Map<String, User> value);
        public abstract Builder setDescriptionText(@Nullable String value);
        public abstract Builder setIdentifier(String value);
        public abstract Builder setImage(@Nullable Image value);
        public abstract Builder setInStock(@Nullable @PinInStock int value);
        public abstract Builder setLink(@Nullable String value);
        public abstract Builder setMedia(@Nullable Map<String, String> value);
        public abstract Builder setNote(@Nullable String value);
        public abstract Builder setTags(@Nullable List<Map<String, Object>> value);
        public abstract Builder setUrl(@Nullable String value);
        public abstract Builder setVisualSearchAttrs(@Nullable Map<String, Object> value);
        public abstract Pin build();
    }
}
```


## Dependencies

The Java output currently has external dependencies. 

### AutoValue
The generated code will reference annotations from [AutoValue](https://github.com/google/auto/tree/master/value) to automatically create implementations of getters/setters for fields and `equals`, `hashCode` and `toString` implementations. Motivation is to use a well adopted framework that provides compile-time generation of boilerplate code which makes the generated code easier to read and maintain.

### Gson
To support JSON deserialization, we will be utilizing the `@SerializedName` annotation in [Gson](https://github.com/google/gson) to facilitate the convertion between Plank types and JSON objects.

### AutoValue Gson
We will be utilizing [AutoValue Gson](https://github.com/rharter/auto-value-gson) to synthesize type adapters from the Gson and AutoValue annotations.

## Implementation Details

### Nullability

For properties that are not required (i.e. nullable), we will annotate them with [`@Nullable`](https://developer.android.com/reference/android/support/annotation/Nullable.html).

Properties that are required, we will annotate them with [`@NonNull`](https://developer.android.com/reference/android/support/annotation/NonNull.html). 

### Enums

Enums are classes in Java. Using Enums over [`@IntDef`](https://developer.android.com/reference/android/support/annotation/IntDef.html) adds about 13x more memory as if you would have used [`@IntDef`](https://developer.android.com/reference/android/support/annotation/IntDef.html).

For similar reasons, we will be utilizing [@StringDef](https://developer.android.com/reference/android/support/annotation/StringDef.html
) for String enumerations.

For more in-depth information, watch this [video](https://www.youtube.com/watch?v=Hzs6OBcvNQE) by Android Developers.


