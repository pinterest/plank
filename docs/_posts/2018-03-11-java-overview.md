---
layout: post
title: "Overview"
categories: java-reference
---

## Dependencies

The Java output currently has external dependencies. 

### Gson
To support JSON deserialization, we will be utilizing the `@SerializedName` annotation in [Gson](https://github.com/google/gson) to facilitate the conversion between Plank types and JSON objects.

## Implementation Details

### Nullability

For properties that are not required (i.e. nullable), we will annotate them with [`@Nullable`](https://developer.android.com/reference/android/support/annotation/Nullable.html).

Properties that are required, we will annotate them with [`@NonNull`](https://developer.android.com/reference/android/support/annotation/NonNull.html). 

### Builder

A builder class is generated as a subclass. Use builders to create brand new instances of the model, or to make copies of existing instances.
Construct a new instance: `Pin pin = Pin.builder().build();`
Generate a builder from an existing model: `Pin anotherPin = pin.toBuilder().build();`

### IsSet Checking

It is sometimes necessary to determine whether a field has been explicitly set. For example, in order to distinguish between a boolean field being explicitly set to false as opposed to just having a default value of false.

`pin.getInStockIsSet() // Returns true only if pin.setInStock(true/false) has been called before`

If the model has been deserialized from Json, `pin.getInStockIsSet()` will return true only if the field was present in the Json.

### TypeAdapters

A Gson TypeAdapterFactory is generated as a sublcass. You should register this TypeAdapterFactory in order in order to guarantee proper behavior for merging and field "is set" checking, as well as for performance benefits.

`gsonBuilder.registerTypeAdapterFactory(new Pin.PinTypeAdapterFactory());`

### Enums

An enum class is created to represent enums defined in the schema.

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
public class Pin {

    public enum PinInStock {
        @SerializedName("-1") UNKNOWN(-1), 
        @SerializedName("0") OUT_OF_STOCK(0), 
        @SerializedName("1") IN_STOCK(1);
        private final int value;
        PinInStock(int value) {
            this.value = value;
        }
        public int getValue() {
            return this.value;
        }
    }

    public static final String TYPE = "pin";

    @SerializedName("attribution") private @Nullable Map<String, String> attribution;
    @SerializedName("attribution_objects") private @Nullable List<PinAttributionObjects> attributionObjects;
    @SerializedName("board") private @Nullable Board board;
    @SerializedName("color") private @Nullable String color;
    @SerializedName("counts") private @Nullable Map<String, Integer> counts;
    @SerializedName("created_at") private @NonNull Date createdAt;
    @SerializedName("creator") private @NonNull Map<String, User> creator;
    @SerializedName("description") private @Nullable String description;
    @SerializedName("id") private @NonNull String uid;
    @SerializedName("image") private @Nullable Image image;
    @SerializedName("in_stock") private @Nullable PinInStock inStock;
    @SerializedName("link") private @Nullable String link;
    @SerializedName("media") private @Nullable Map<String, String> media;
    @SerializedName("note") private @Nullable String note;
    @SerializedName("tags") private @Nullable List<Map<String, Object>> tags;
    @SerializedName("url") private @Nullable String url;
    @SerializedName("visual_search_attrs") private @Nullable Map<String, Object> visualSearchAttrs;

    private static final int ATTRIBUTION_INDEX = 0;
    private static final int ATTRIBUTION_OBJECTS_INDEX = 1;
    private static final int BOARD_INDEX = 2;
    // ... omitted for brevity
    private static final int VISUAL_SEARCH_ATTRS_INDEX = 16;

    private boolean[] _bits;

    private Pin(
        @Nullable Map<String, String> attribution,
        @Nullable List<PinAttributionObjects> attributionObjects,
        // ... omitted for brevity
        boolean[] _bits
    ) {
        this.attribution = attribution;
        this.attributionObjects = attributionObjects;
        // ... omitted for brevity
        this._bits = _bits;
    }

    @NonNull
    public static Pin.Builder builder() {
        return new Pin.Builder();
    }

    @NonNull
    public Pin.Builder toBuilder() {
        return new Pin.Builder(this);
    }

    @NonNull
    public Pin mergeFrom(@NonNull Pin model) {
        Pin.Builder builder = this.toBuilder();
        builder.mergeFrom(model);
        return builder.build();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Pin that = (Pin) o;
        return Objects.equals(this.inStock, that.inStock) &&
        Objects.equals(this.attribution, that.attribution) &&
        // ... omitted for brevity
        Objects.equals(this.visualSearchAttrs, that.visualSearchAttrs);
    }

    @Override
    public int hashCode() {
        return Objects.hash(attribution,
        attributionObjects,
        // ... omitted for brevity
        visualSearchAttrs);
    }

    /**
     * GETTERS
     */
    
    public @Nullable Map<String, String> getAttribution() {
        return this.attribution;
    }

    public @Nullable List<PinAttributionObjects> getAttributionObjects() {
        return this.attributionObjects;
    }

    // ...omitted for brevity

    public @Nullable String getUrl() {
        return this.url;
    }

    public @Nullable Map<String, Object> getVisualSearchAttrs() {
        return this.visualSearchAttrs;
    }

    /**
     * IsSet CHECKERS
     */

    public boolean getAttributionIsSet() {
        return this._bits.length > ATTRIBUTION_INDEX && this._bits[ATTRIBUTION_INDEX];
    }

    public boolean getAttributionObjectsIsSet() {
        return this._bits.length > ATTRIBUTION_OBJECTS_INDEX && this._bits[ATTRIBUTION_OBJECTS_INDEX];
    }

    // ... omitted for brevity

    /**
     * BUILDER
     */
    public static class Builder {

        private @Nullable Map<String, String> attribution;
        private @Nullable List<PinAttributionObjects> attributionObjects;
        // ... omitted for brevity
        private @Nullable Map<String, Object> visualSearchAttrs;

        private boolean[] _bits;

        private Builder() {
            this._bits = new boolean[17];
        }

        private Builder(@NonNull Pin model) {
            this.attribution = model.attribution;
            this.attributionObjects = model.attributionObjects;
            // ... omitted for brevity
            this._bits = model._bits;
        }

        @NonNull
        public Builder setAttribution(@Nullable Map<String, String> value) {
            this.attribution = value;
            if (this._bits.length > ATTRIBUTION_INDEX) {
                this._bits[ATTRIBUTION_INDEX] = true;
            }
            return this;
        }

        // ... the rest of the fields are omitted for brevity

        public @Nullable Map<String, String> getAttribution() {
            return this.attribution;
        }

        // ... the rest of the fields are omitted for brevity

        @NonNull
        public Pin build() {
            return new Pin(
            this.attribution,
            this.attributionObjects,
            // ... omitted for brevity
            this._bits
            );
        }

        public void mergeFrom(@NonNull Pin model) {
            if (model._bits.length > ATTRIBUTION_INDEX && model._bits[ATTRIBUTION_INDEX]) {
                this.attribution = model.attribution;
                this._bits[ATTRIBUTION_INDEX] = true;
            }
            if (model._bits.length > ATTRIBUTION_OBJECTS_INDEX && model._bits[ATTRIBUTION_OBJECTS_INDEX]) {
                this.attributionObjects = model.attributionObjects;
                this._bits[ATTRIBUTION_OBJECTS_INDEX] = true;
            }
            
            // ... omitted for brevity
        }
    }

    /**
     * TypeAdapterFactory
     */
    public static class PinTypeAdapterFactory implements TypeAdapterFactory {

        @Nullable
        @Override
        public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
            if (!Pin.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new PinTypeAdapter(gson);
        }
    }

    /**
     * TypeAdapterFactory
     */
    private static class PinTypeAdapter extends TypeAdapter<Pin> {
        // ... omitted for brevity
    }

    /**
     * Algabraeic Data Type
     */
    public static final class PinAttributionObjects {

        private @Nullable Board value0;
        private @Nullable User value1;

        private PinAttributionObjects() {
        }

        public PinAttributionObjects(@NonNull Board value) {
            this.value0 = value;
        }

        public PinAttributionObjects(@NonNull User value) {
            this.value1 = value;
        }

        @Nullable
        public <R> R matchPinAttributionObjects(PinAttributionObjectsMatcher<R> matcher) {
            if (value0 != null) {
                return matcher.match(value0);
            }
            if (value1 != null) {
                return matcher.match(value1);
            }
            return null;
        }

        public static class PinAttributionObjectsTypeAdapterFactory implements TypeAdapterFactory {

            @Nullable
            @Override
            public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
                if (!PinAttributionObjects.class.isAssignableFrom(typeToken.getRawType())) {
                    return null;
                }
                return (TypeAdapter<T>) new PinAttributionObjectsTypeAdapter(gson);
            }
        }

        private static class PinAttributionObjectsTypeAdapter extends TypeAdapter<PinAttributionObjects> {

            private final Gson gson;
            private TypeAdapter<Board> boardTypeAdapter;
            private TypeAdapter<User> userTypeAdapter;

            public PinAttributionObjectsTypeAdapter(Gson gson) {
                this.gson = gson;
            }

            @Override
            public void write(@NonNull JsonWriter writer, PinAttributionObjects value) throws IOException {
                writer.nullValue();
            }

            @Nullable
            @Override
            public PinAttributionObjects read(@NonNull JsonReader reader) throws IOException {
                if (reader.peek() == JsonToken.NULL) {
                    reader.nextNull();
                    return null;
                }
                if (reader.peek() == JsonToken.BEGIN_OBJECT) {
                    JsonObject jsonObject = this.gson.fromJson(reader, JsonObject.class);
                    String type;
                    try {
                        type = jsonObject.get("type").getAsString();
                    } catch (Exception e) {
                        return new PinAttributionObjects();
                    }
                    if (type == null) {
                        return new PinAttributionObjects();
                    }
                    switch (type) {
                        case ("board"):
                            if (this.boardTypeAdapter == null) {
                                this.boardTypeAdapter = this.gson.getAdapter(Board.class).nullSafe();
                            }
                            return new PinAttributionObjects(boardTypeAdapter.fromJsonTree(jsonObject));
                        case ("user"):
                            if (this.userTypeAdapter == null) {
                                this.userTypeAdapter = this.gson.getAdapter(User.class).nullSafe();
                            }
                            return new PinAttributionObjects(userTypeAdapter.fromJsonTree(jsonObject));
                        default:
                            return new PinAttributionObjects();
                    }
                }
                reader.skipValue();
                return new PinAttributionObjects();
            }
        }

        public interface PinAttributionObjectsMatcher<R> {
            R match(@NonNull Board value0);
            R match(@NonNull User value1);
        }
    }
}
```
