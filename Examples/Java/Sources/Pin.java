//
// Pin.java
// Autogenerated by plank
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

package com.pinterest.models;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.TypeAdapter;
import com.google.gson.TypeAdapterFactory;
import com.google.gson.annotations.SerializedName;
import com.google.gson.reflect.TypeToken;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonToken;
import com.google.gson.stream.JsonWriter;
import java.io.IOException;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

interface PinAttributionObjectsMatcher<R> {
    R match(@Nullable Board value0);
    R match(@Nullable User value1);
}

public class Pin {

    public enum PinInStock {
        UNKNOWN(-1), 
        OUT_OF_STOCK(0), 
        IN_STOCK(1);
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

    static final private int ATTRIBUTION_INDEX = 0;
    static final private int ATTRIBUTION_OBJECTS_INDEX = 1;
    static final private int BOARD_INDEX = 2;
    static final private int COLOR_INDEX = 3;
    static final private int COUNTS_INDEX = 4;
    static final private int CREATED_AT_INDEX = 5;
    static final private int CREATOR_INDEX = 6;
    static final private int DESCRIPTION_INDEX = 7;
    static final private int ID_INDEX = 8;
    static final private int IMAGE_INDEX = 9;
    static final private int IN_STOCK_INDEX = 10;
    static final private int LINK_INDEX = 11;
    static final private int MEDIA_INDEX = 12;
    static final private int NOTE_INDEX = 13;
    static final private int TAGS_INDEX = 14;
    static final private int URL_INDEX = 15;
    static final private int VISUAL_SEARCH_ATTRS_INDEX = 16;

    private boolean[] _bits = new boolean[17];

    private Pin(
        @Nullable Map<String, String> attribution,
        @Nullable List<PinAttributionObjects> attributionObjects,
        @Nullable Board board,
        @Nullable String color,
        @Nullable Map<String, Integer> counts,
        @NonNull Date createdAt,
        @NonNull Map<String, User> creator,
        @Nullable String description,
        @NonNull String uid,
        @Nullable Image image,
        @Nullable PinInStock inStock,
        @Nullable String link,
        @Nullable Map<String, String> media,
        @Nullable String note,
        @Nullable List<Map<String, Object>> tags,
        @Nullable String url,
        @Nullable Map<String, Object> visualSearchAttrs,
        boolean[] _bits
    ) {
        this.attribution = attribution;
        this.attributionObjects = attributionObjects;
        this.board = board;
        this.color = color;
        this.counts = counts;
        this.createdAt = createdAt;
        this.creator = creator;
        this.description = description;
        this.uid = uid;
        this.image = image;
        this.inStock = inStock;
        this.link = link;
        this.media = media;
        this.note = note;
        this.tags = tags;
        this.url = url;
        this.visualSearchAttrs = visualSearchAttrs;
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
        return Objects.equals(this.attribution, that.attribution) &&
        Objects.equals(this.attributionObjects, that.attributionObjects) &&
        Objects.equals(this.board, that.board) &&
        Objects.equals(this.color, that.color) &&
        Objects.equals(this.counts, that.counts) &&
        Objects.equals(this.createdAt, that.createdAt) &&
        Objects.equals(this.creator, that.creator) &&
        Objects.equals(this.description, that.description) &&
        Objects.equals(this.uid, that.uid) &&
        Objects.equals(this.image, that.image) &&
        Objects.equals(this.inStock, that.inStock) &&
        Objects.equals(this.link, that.link) &&
        Objects.equals(this.media, that.media) &&
        Objects.equals(this.note, that.note) &&
        Objects.equals(this.tags, that.tags) &&
        Objects.equals(this.url, that.url) &&
        Objects.equals(this.visualSearchAttrs, that.visualSearchAttrs);
    }

    @Override
    public int hashCode() {
        return Objects.hash(attribution,
        attributionObjects,
        board,
        color,
        counts,
        createdAt,
        creator,
        description,
        uid,
        image,
        inStock,
        link,
        media,
        note,
        tags,
        url,
        visualSearchAttrs);
    }

    public @Nullable Map<String, String> getAttribution() {
        return this.attribution;
    }

    public @Nullable List<PinAttributionObjects> getAttributionObjects() {
        return this.attributionObjects;
    }

    public @Nullable Board getBoard() {
        return this.board;
    }

    public @Nullable String getColor() {
        return this.color;
    }

    public @Nullable Map<String, Integer> getCounts() {
        return this.counts;
    }

    public @NonNull Date getCreatedAt() {
        return this.createdAt;
    }

    public @NonNull Map<String, User> getCreator() {
        return this.creator;
    }

    public @Nullable String getDescription() {
        return this.description;
    }

    public @NonNull String getUid() {
        return this.uid;
    }

    public @Nullable Image getImage() {
        return this.image;
    }

    public @Nullable PinInStock getInStock() {
        return this.inStock;
    }

    public @Nullable String getLink() {
        return this.link;
    }

    public @Nullable Map<String, String> getMedia() {
        return this.media;
    }

    public @Nullable String getNote() {
        return this.note;
    }

    public @Nullable List<Map<String, Object>> getTags() {
        return this.tags;
    }

    public @Nullable String getUrl() {
        return this.url;
    }

    public @Nullable Map<String, Object> getVisualSearchAttrs() {
        return this.visualSearchAttrs;
    }

    public boolean getAttributionIsSet() {
        return this._bits.length > ATTRIBUTION_INDEX && this._bits[ATTRIBUTION_INDEX];
    }

    public boolean getAttributionObjectsIsSet() {
        return this._bits.length > ATTRIBUTION_OBJECTS_INDEX && this._bits[ATTRIBUTION_OBJECTS_INDEX];
    }

    public boolean getBoardIsSet() {
        return this._bits.length > BOARD_INDEX && this._bits[BOARD_INDEX];
    }

    public boolean getColorIsSet() {
        return this._bits.length > COLOR_INDEX && this._bits[COLOR_INDEX];
    }

    public boolean getCountsIsSet() {
        return this._bits.length > COUNTS_INDEX && this._bits[COUNTS_INDEX];
    }

    public boolean getCreatedAtIsSet() {
        return this._bits.length > CREATED_AT_INDEX && this._bits[CREATED_AT_INDEX];
    }

    public boolean getCreatorIsSet() {
        return this._bits.length > CREATOR_INDEX && this._bits[CREATOR_INDEX];
    }

    public boolean getDescriptionIsSet() {
        return this._bits.length > DESCRIPTION_INDEX && this._bits[DESCRIPTION_INDEX];
    }

    public boolean getUidIsSet() {
        return this._bits.length > ID_INDEX && this._bits[ID_INDEX];
    }

    public boolean getImageIsSet() {
        return this._bits.length > IMAGE_INDEX && this._bits[IMAGE_INDEX];
    }

    public boolean getInStockIsSet() {
        return this._bits.length > IN_STOCK_INDEX && this._bits[IN_STOCK_INDEX];
    }

    public boolean getLinkIsSet() {
        return this._bits.length > LINK_INDEX && this._bits[LINK_INDEX];
    }

    public boolean getMediaIsSet() {
        return this._bits.length > MEDIA_INDEX && this._bits[MEDIA_INDEX];
    }

    public boolean getNoteIsSet() {
        return this._bits.length > NOTE_INDEX && this._bits[NOTE_INDEX];
    }

    public boolean getTagsIsSet() {
        return this._bits.length > TAGS_INDEX && this._bits[TAGS_INDEX];
    }

    public boolean getUrlIsSet() {
        return this._bits.length > URL_INDEX && this._bits[URL_INDEX];
    }

    public boolean getVisualSearchAttrsIsSet() {
        return this._bits.length > VISUAL_SEARCH_ATTRS_INDEX && this._bits[VISUAL_SEARCH_ATTRS_INDEX];
    }

    public static class Builder {

        private @Nullable Map<String, String> attribution;
        private @Nullable List<PinAttributionObjects> attributionObjects;
        private @Nullable Board board;
        private @Nullable String color;
        private @Nullable Map<String, Integer> counts;
        private @NonNull Date createdAt;
        private @NonNull Map<String, User> creator;
        private @Nullable String description;
        private @NonNull String uid;
        private @Nullable Image image;
        private @Nullable PinInStock inStock;
        private @Nullable String link;
        private @Nullable Map<String, String> media;
        private @Nullable String note;
        private @Nullable List<Map<String, Object>> tags;
        private @Nullable String url;
        private @Nullable Map<String, Object> visualSearchAttrs;

        private boolean[] _bits = new boolean[17];

        private Builder() {
        }

        private Builder(@NonNull Pin model) {
            this.attribution = model.attribution;
            this.attributionObjects = model.attributionObjects;
            this.board = model.board;
            this.color = model.color;
            this.counts = model.counts;
            this.createdAt = model.createdAt;
            this.creator = model.creator;
            this.description = model.description;
            this.uid = model.uid;
            this.image = model.image;
            this.inStock = model.inStock;
            this.link = model.link;
            this.media = model.media;
            this.note = model.note;
            this.tags = model.tags;
            this.url = model.url;
            this.visualSearchAttrs = model.visualSearchAttrs;
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

        @NonNull
        public Builder setAttributionObjects(@Nullable List<PinAttributionObjects> value) {
            this.attributionObjects = value;
            if (this._bits.length > ATTRIBUTION_OBJECTS_INDEX) {
                this._bits[ATTRIBUTION_OBJECTS_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setBoard(@Nullable Board value) {
            this.board = value;
            if (this._bits.length > BOARD_INDEX) {
                this._bits[BOARD_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setColor(@Nullable String value) {
            this.color = value;
            if (this._bits.length > COLOR_INDEX) {
                this._bits[COLOR_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setCounts(@Nullable Map<String, Integer> value) {
            this.counts = value;
            if (this._bits.length > COUNTS_INDEX) {
                this._bits[COUNTS_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setCreatedAt(@NonNull Date value) {
            this.createdAt = value;
            if (this._bits.length > CREATED_AT_INDEX) {
                this._bits[CREATED_AT_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setCreator(@NonNull Map<String, User> value) {
            this.creator = value;
            if (this._bits.length > CREATOR_INDEX) {
                this._bits[CREATOR_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setDescription(@Nullable String value) {
            this.description = value;
            if (this._bits.length > DESCRIPTION_INDEX) {
                this._bits[DESCRIPTION_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setUid(@NonNull String value) {
            this.uid = value;
            if (this._bits.length > ID_INDEX) {
                this._bits[ID_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setImage(@Nullable Image value) {
            this.image = value;
            if (this._bits.length > IMAGE_INDEX) {
                this._bits[IMAGE_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setInStock(@Nullable PinInStock value) {
            this.inStock = value;
            if (this._bits.length > IN_STOCK_INDEX) {
                this._bits[IN_STOCK_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setLink(@Nullable String value) {
            this.link = value;
            if (this._bits.length > LINK_INDEX) {
                this._bits[LINK_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setMedia(@Nullable Map<String, String> value) {
            this.media = value;
            if (this._bits.length > MEDIA_INDEX) {
                this._bits[MEDIA_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setNote(@Nullable String value) {
            this.note = value;
            if (this._bits.length > NOTE_INDEX) {
                this._bits[NOTE_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setTags(@Nullable List<Map<String, Object>> value) {
            this.tags = value;
            if (this._bits.length > TAGS_INDEX) {
                this._bits[TAGS_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setUrl(@Nullable String value) {
            this.url = value;
            if (this._bits.length > URL_INDEX) {
                this._bits[URL_INDEX] = true;
            }
            return this;
        }

        @NonNull
        public Builder setVisualSearchAttrs(@Nullable Map<String, Object> value) {
            this.visualSearchAttrs = value;
            if (this._bits.length > VISUAL_SEARCH_ATTRS_INDEX) {
                this._bits[VISUAL_SEARCH_ATTRS_INDEX] = true;
            }
            return this;
        }

        public @Nullable Map<String, String> getAttribution() {
            return this.attribution;
        }

        public @Nullable List<PinAttributionObjects> getAttributionObjects() {
            return this.attributionObjects;
        }

        public @Nullable Board getBoard() {
            return this.board;
        }

        public @Nullable String getColor() {
            return this.color;
        }

        public @Nullable Map<String, Integer> getCounts() {
            return this.counts;
        }

        public @NonNull Date getCreatedAt() {
            return this.createdAt;
        }

        public @NonNull Map<String, User> getCreator() {
            return this.creator;
        }

        public @Nullable String getDescription() {
            return this.description;
        }

        public @NonNull String getUid() {
            return this.uid;
        }

        public @Nullable Image getImage() {
            return this.image;
        }

        public @Nullable PinInStock getInStock() {
            return this.inStock;
        }

        public @Nullable String getLink() {
            return this.link;
        }

        public @Nullable Map<String, String> getMedia() {
            return this.media;
        }

        public @Nullable String getNote() {
            return this.note;
        }

        public @Nullable List<Map<String, Object>> getTags() {
            return this.tags;
        }

        public @Nullable String getUrl() {
            return this.url;
        }

        public @Nullable Map<String, Object> getVisualSearchAttrs() {
            return this.visualSearchAttrs;
        }

        @NonNull
        public Pin build() {
            return new Pin(
            this.attribution,
            this.attributionObjects,
            this.board,
            this.color,
            this.counts,
            this.createdAt,
            this.creator,
            this.description,
            this.uid,
            this.image,
            this.inStock,
            this.link,
            this.media,
            this.note,
            this.tags,
            this.url,
            this.visualSearchAttrs,
            this._bits
            );
        }

        public void mergeFrom(@NonNull Pin model) {
            if (model.getAttributionIsSet()) {
                this.attribution = model.attribution;
                if (this._bits.length > ATTRIBUTION_INDEX) {
                    this._bits[ATTRIBUTION_INDEX] = true;
                }
            }
            if (model.getAttributionObjectsIsSet()) {
                this.attributionObjects = model.attributionObjects;
                if (this._bits.length > ATTRIBUTION_OBJECTS_INDEX) {
                    this._bits[ATTRIBUTION_OBJECTS_INDEX] = true;
                }
            }
            if (model.getBoardIsSet()) {
                this.board = model.board;
                if (this._bits.length > BOARD_INDEX) {
                    this._bits[BOARD_INDEX] = true;
                }
            }
            if (model.getColorIsSet()) {
                this.color = model.color;
                if (this._bits.length > COLOR_INDEX) {
                    this._bits[COLOR_INDEX] = true;
                }
            }
            if (model.getCountsIsSet()) {
                this.counts = model.counts;
                if (this._bits.length > COUNTS_INDEX) {
                    this._bits[COUNTS_INDEX] = true;
                }
            }
            if (model.getCreatedAtIsSet()) {
                this.createdAt = model.createdAt;
                if (this._bits.length > CREATED_AT_INDEX) {
                    this._bits[CREATED_AT_INDEX] = true;
                }
            }
            if (model.getCreatorIsSet()) {
                this.creator = model.creator;
                if (this._bits.length > CREATOR_INDEX) {
                    this._bits[CREATOR_INDEX] = true;
                }
            }
            if (model.getDescriptionIsSet()) {
                this.description = model.description;
                if (this._bits.length > DESCRIPTION_INDEX) {
                    this._bits[DESCRIPTION_INDEX] = true;
                }
            }
            if (model.getUidIsSet()) {
                this.uid = model.uid;
                if (this._bits.length > ID_INDEX) {
                    this._bits[ID_INDEX] = true;
                }
            }
            if (model.getImageIsSet()) {
                this.image = model.image;
                if (this._bits.length > IMAGE_INDEX) {
                    this._bits[IMAGE_INDEX] = true;
                }
            }
            if (model.getInStockIsSet()) {
                this.inStock = model.inStock;
                if (this._bits.length > IN_STOCK_INDEX) {
                    this._bits[IN_STOCK_INDEX] = true;
                }
            }
            if (model.getLinkIsSet()) {
                this.link = model.link;
                if (this._bits.length > LINK_INDEX) {
                    this._bits[LINK_INDEX] = true;
                }
            }
            if (model.getMediaIsSet()) {
                this.media = model.media;
                if (this._bits.length > MEDIA_INDEX) {
                    this._bits[MEDIA_INDEX] = true;
                }
            }
            if (model.getNoteIsSet()) {
                this.note = model.note;
                if (this._bits.length > NOTE_INDEX) {
                    this._bits[NOTE_INDEX] = true;
                }
            }
            if (model.getTagsIsSet()) {
                this.tags = model.tags;
                if (this._bits.length > TAGS_INDEX) {
                    this._bits[TAGS_INDEX] = true;
                }
            }
            if (model.getUrlIsSet()) {
                this.url = model.url;
                if (this._bits.length > URL_INDEX) {
                    this._bits[URL_INDEX] = true;
                }
            }
            if (model.getVisualSearchAttrsIsSet()) {
                this.visualSearchAttrs = model.visualSearchAttrs;
                if (this._bits.length > VISUAL_SEARCH_ATTRS_INDEX) {
                    this._bits[VISUAL_SEARCH_ATTRS_INDEX] = true;
                }
            }
        }
    }

    public static class PinTypeAdapterFactory implements TypeAdapterFactory {

        @Nullable
        @Override
        public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
            if (!Pin.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new PinTypeAdapter(gson, this, typeToken);
        }
    }

    public static class PinTypeAdapter extends TypeAdapter<Pin> {

        final private PinTypeAdapterFactory factory;
        final private Gson gson;
        final private TypeToken typeToken;
        private TypeAdapter<Pin> delegateTypeAdapter;

        private TypeAdapter<Board> boardTypeAdapter;
        private TypeAdapter<Date> dateTypeAdapter;
        private TypeAdapter<Image> imageTypeAdapter;
        private TypeAdapter<List<Map<String, Object>>> list_Map_String__Object__TypeAdapter;
        private TypeAdapter<List<PinAttributionObjects>> list_PinAttributionObjects_TypeAdapter;
        private TypeAdapter<Map<String, Integer>> map_String__Integer_TypeAdapter;
        private TypeAdapter<Map<String, Object>> map_String__Object_TypeAdapter;
        private TypeAdapter<Map<String, String>> map_String__String_TypeAdapter;
        private TypeAdapter<Map<String, User>> map_String__User_TypeAdapter;
        private TypeAdapter<PinInStock> pinInStockTypeAdapter;
        private TypeAdapter<String> stringTypeAdapter;

        public PinTypeAdapter(@NonNull Gson gson, PinTypeAdapterFactory factory, TypeToken typeToken) {
            this.factory = factory;
            this.gson = gson;
            this.typeToken = typeToken;
        }

        @Override
        public void write(@NonNull JsonWriter writer, Pin value) throws IOException {
            if (this.delegateTypeAdapter == null) {
                this.delegateTypeAdapter = this.gson.getDelegateAdapter(this.factory, this.typeToken);
            }
            writer.setSerializeNulls(false);
            this.delegateTypeAdapter.write(writer, value);
        }

        @Override
        @Nullable
        public Pin read(@NonNull JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = Pin.builder();
            boolean[] bits = null;
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                switch (name) {
                    case ("attribution"):
                        if (this.map_String__String_TypeAdapter == null) {
                            this.map_String__String_TypeAdapter = this.gson.getAdapter(new TypeToken<Map<String, String>>(){}).nullSafe();
                        }
                        builder.setAttribution(this.map_String__String_TypeAdapter.read(reader));
                        break;
                    case ("attribution_objects"):
                        if (this.list_PinAttributionObjects_TypeAdapter == null) {
                            this.list_PinAttributionObjects_TypeAdapter = this.gson.getAdapter(new TypeToken<List<PinAttributionObjects>>(){}).nullSafe();
                        }
                        builder.setAttributionObjects(this.list_PinAttributionObjects_TypeAdapter.read(reader));
                        break;
                    case ("board"):
                        if (this.boardTypeAdapter == null) {
                            this.boardTypeAdapter = this.gson.getAdapter(Board.class).nullSafe();
                        }
                        builder.setBoard(this.boardTypeAdapter.read(reader));
                        break;
                    case ("color"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setColor(this.stringTypeAdapter.read(reader));
                        break;
                    case ("counts"):
                        if (this.map_String__Integer_TypeAdapter == null) {
                            this.map_String__Integer_TypeAdapter = this.gson.getAdapter(new TypeToken<Map<String, Integer>>(){}).nullSafe();
                        }
                        builder.setCounts(this.map_String__Integer_TypeAdapter.read(reader));
                        break;
                    case ("created_at"):
                        if (this.dateTypeAdapter == null) {
                            this.dateTypeAdapter = this.gson.getAdapter(Date.class).nullSafe();
                        }
                        builder.setCreatedAt(this.dateTypeAdapter.read(reader));
                        break;
                    case ("creator"):
                        if (this.map_String__User_TypeAdapter == null) {
                            this.map_String__User_TypeAdapter = this.gson.getAdapter(new TypeToken<Map<String, User>>(){}).nullSafe();
                        }
                        builder.setCreator(this.map_String__User_TypeAdapter.read(reader));
                        break;
                    case ("description"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setDescription(this.stringTypeAdapter.read(reader));
                        break;
                    case ("id"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setUid(this.stringTypeAdapter.read(reader));
                        break;
                    case ("image"):
                        if (this.imageTypeAdapter == null) {
                            this.imageTypeAdapter = this.gson.getAdapter(Image.class).nullSafe();
                        }
                        builder.setImage(this.imageTypeAdapter.read(reader));
                        break;
                    case ("in_stock"):
                        if (this.pinInStockTypeAdapter == null) {
                            this.pinInStockTypeAdapter = this.gson.getAdapter(PinInStock.class).nullSafe();
                        }
                        builder.setInStock(this.pinInStockTypeAdapter.read(reader));
                        break;
                    case ("link"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setLink(this.stringTypeAdapter.read(reader));
                        break;
                    case ("media"):
                        if (this.map_String__String_TypeAdapter == null) {
                            this.map_String__String_TypeAdapter = this.gson.getAdapter(new TypeToken<Map<String, String>>(){}).nullSafe();
                        }
                        builder.setMedia(this.map_String__String_TypeAdapter.read(reader));
                        break;
                    case ("note"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setNote(this.stringTypeAdapter.read(reader));
                        break;
                    case ("tags"):
                        if (this.list_Map_String__Object__TypeAdapter == null) {
                            this.list_Map_String__Object__TypeAdapter = this.gson.getAdapter(new TypeToken<List<Map<String, Object>>>(){}).nullSafe();
                        }
                        builder.setTags(this.list_Map_String__Object__TypeAdapter.read(reader));
                        break;
                    case ("url"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setUrl(this.stringTypeAdapter.read(reader));
                        break;
                    case ("visual_search_attrs"):
                        if (this.map_String__Object_TypeAdapter == null) {
                            this.map_String__Object_TypeAdapter = this.gson.getAdapter(new TypeToken<Map<String, Object>>(){}).nullSafe();
                        }
                        builder.setVisualSearchAttrs(this.map_String__Object_TypeAdapter.read(reader));
                        break;
                    case ("_bits"):
                        bits = new boolean[17];
                        int i = 0;
                        reader.beginArray();
                        while (reader.hasNext() && i < 17) {
                            bits[i] = reader.nextBoolean();
                            i++;
                        }
                        reader.endArray();
                        break;
                    default:
                        reader.skipValue();
                }
            }
            reader.endObject();
            if (bits != null) {
                builder._bits = bits;
            }
            return builder.build();
        }
    }

    public static final class PinAttributionObjects<R> {

        public enum InternalStorage {
            BOARD(0), 
            USER(1);
            private final int value;
            InternalStorage(int value) {
                this.value = value;
            }
            public int getValue() {
                return this.value;
            }
        }

        private @Nullable Board value0;
        private @Nullable User value1;

        static private InternalStorage internalStorage;

        private PinAttributionObjects() {
        }

        public R matchPinAttributionObjects(PinAttributionObjectsMatcher<R> matcher) {
            // TODO: Implement this!
            return null;
        }
    }
}
