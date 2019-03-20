//
// Pin.java
// Autogenerated by plank
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

package com.pinterest.models;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
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

    static final private int ATTRIBUTION_SET = 1 << 0;
    static final private int ATTRIBUTION_OBJECTS_SET = 1 << 1;
    static final private int BOARD_SET = 1 << 2;
    static final private int COLOR_SET = 1 << 3;
    static final private int COUNTS_SET = 1 << 4;
    static final private int CREATED_AT_SET = 1 << 5;
    static final private int CREATOR_SET = 1 << 6;
    static final private int DESCRIPTION_SET = 1 << 7;
    static final private int ID_SET = 1 << 8;
    static final private int IMAGE_SET = 1 << 9;
    static final private int IN_STOCK_SET = 1 << 10;
    static final private int LINK_SET = 1 << 11;
    static final private int MEDIA_SET = 1 << 12;
    static final private int NOTE_SET = 1 << 13;
    static final private int TAGS_SET = 1 << 14;
    static final private int URL_SET = 1 << 15;
    static final private int VISUAL_SEARCH_ATTRS_SET = 1 << 16;

    private int _bits = 0;

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
        int _bits
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

    public static Pin.Builder builder() {
        return new Pin.Builder();
    }

    public Pin.Builder toBuilder() {
        return new Pin.Builder(this);
    }

    public Pin mergeFrom(Pin model) {
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
        return (this._bits & ATTRIBUTION_SET) == ATTRIBUTION_SET;
    }

    public boolean getAttributionObjectsIsSet() {
        return (this._bits & ATTRIBUTION_OBJECTS_SET) == ATTRIBUTION_OBJECTS_SET;
    }

    public boolean getBoardIsSet() {
        return (this._bits & BOARD_SET) == BOARD_SET;
    }

    public boolean getColorIsSet() {
        return (this._bits & COLOR_SET) == COLOR_SET;
    }

    public boolean getCountsIsSet() {
        return (this._bits & COUNTS_SET) == COUNTS_SET;
    }

    public boolean getCreatedAtIsSet() {
        return (this._bits & CREATED_AT_SET) == CREATED_AT_SET;
    }

    public boolean getCreatorIsSet() {
        return (this._bits & CREATOR_SET) == CREATOR_SET;
    }

    public boolean getDescriptionIsSet() {
        return (this._bits & DESCRIPTION_SET) == DESCRIPTION_SET;
    }

    public boolean getUidIsSet() {
        return (this._bits & ID_SET) == ID_SET;
    }

    public boolean getImageIsSet() {
        return (this._bits & IMAGE_SET) == IMAGE_SET;
    }

    public boolean getInStockIsSet() {
        return (this._bits & IN_STOCK_SET) == IN_STOCK_SET;
    }

    public boolean getLinkIsSet() {
        return (this._bits & LINK_SET) == LINK_SET;
    }

    public boolean getMediaIsSet() {
        return (this._bits & MEDIA_SET) == MEDIA_SET;
    }

    public boolean getNoteIsSet() {
        return (this._bits & NOTE_SET) == NOTE_SET;
    }

    public boolean getTagsIsSet() {
        return (this._bits & TAGS_SET) == TAGS_SET;
    }

    public boolean getUrlIsSet() {
        return (this._bits & URL_SET) == URL_SET;
    }

    public boolean getVisualSearchAttrsIsSet() {
        return (this._bits & VISUAL_SEARCH_ATTRS_SET) == VISUAL_SEARCH_ATTRS_SET;
    }

    public static class Builder {

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

        private int _bits = 0;

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

        public Builder setAttribution(@Nullable Map<String, String> value) {
            this.attribution = value;
            this._bits |= ATTRIBUTION_SET;
            return this;
        }

        public Builder setAttributionObjects(@Nullable List<PinAttributionObjects> value) {
            this.attributionObjects = value;
            this._bits |= ATTRIBUTION_OBJECTS_SET;
            return this;
        }

        public Builder setBoard(@Nullable Board value) {
            this.board = value;
            this._bits |= BOARD_SET;
            return this;
        }

        public Builder setColor(@Nullable String value) {
            this.color = value;
            this._bits |= COLOR_SET;
            return this;
        }

        public Builder setCounts(@Nullable Map<String, Integer> value) {
            this.counts = value;
            this._bits |= COUNTS_SET;
            return this;
        }

        public Builder setCreatedAt(@NonNull Date value) {
            this.createdAt = value;
            this._bits |= CREATED_AT_SET;
            return this;
        }

        public Builder setCreator(@NonNull Map<String, User> value) {
            this.creator = value;
            this._bits |= CREATOR_SET;
            return this;
        }

        public Builder setDescription(@Nullable String value) {
            this.description = value;
            this._bits |= DESCRIPTION_SET;
            return this;
        }

        public Builder setUid(@NonNull String value) {
            this.uid = value;
            this._bits |= ID_SET;
            return this;
        }

        public Builder setImage(@Nullable Image value) {
            this.image = value;
            this._bits |= IMAGE_SET;
            return this;
        }

        public Builder setInStock(@Nullable PinInStock value) {
            this.inStock = value;
            this._bits |= IN_STOCK_SET;
            return this;
        }

        public Builder setLink(@Nullable String value) {
            this.link = value;
            this._bits |= LINK_SET;
            return this;
        }

        public Builder setMedia(@Nullable Map<String, String> value) {
            this.media = value;
            this._bits |= MEDIA_SET;
            return this;
        }

        public Builder setNote(@Nullable String value) {
            this.note = value;
            this._bits |= NOTE_SET;
            return this;
        }

        public Builder setTags(@Nullable List<Map<String, Object>> value) {
            this.tags = value;
            this._bits |= TAGS_SET;
            return this;
        }

        public Builder setUrl(@Nullable String value) {
            this.url = value;
            this._bits |= URL_SET;
            return this;
        }

        public Builder setVisualSearchAttrs(@Nullable Map<String, Object> value) {
            this.visualSearchAttrs = value;
            this._bits |= VISUAL_SEARCH_ATTRS_SET;
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

        public void mergeFrom(Pin model) {
            if (model.getAttributionIsSet()) {
                this.attribution = model.attribution;
            }
            if (model.getAttributionObjectsIsSet()) {
                this.attributionObjects = model.attributionObjects;
            }
            if (model.getBoardIsSet()) {
                this.board = model.board;
            }
            if (model.getColorIsSet()) {
                this.color = model.color;
            }
            if (model.getCountsIsSet()) {
                this.counts = model.counts;
            }
            if (model.getCreatedAtIsSet()) {
                this.createdAt = model.createdAt;
            }
            if (model.getCreatorIsSet()) {
                this.creator = model.creator;
            }
            if (model.getDescriptionIsSet()) {
                this.description = model.description;
            }
            if (model.getUidIsSet()) {
                this.uid = model.uid;
            }
            if (model.getImageIsSet()) {
                this.image = model.image;
            }
            if (model.getInStockIsSet()) {
                this.inStock = model.inStock;
            }
            if (model.getLinkIsSet()) {
                this.link = model.link;
            }
            if (model.getMediaIsSet()) {
                this.media = model.media;
            }
            if (model.getNoteIsSet()) {
                this.note = model.note;
            }
            if (model.getTagsIsSet()) {
                this.tags = model.tags;
            }
            if (model.getUrlIsSet()) {
                this.url = model.url;
            }
            if (model.getVisualSearchAttrsIsSet()) {
                this.visualSearchAttrs = model.visualSearchAttrs;
            }
        }
    }

    public static class PinTypeAdapterFactory implements TypeAdapterFactory {

        @Override
        public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> typeToken) {
            if (!Pin.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new PinTypeAdapter(gson, this, typeToken);
        }
    }

    public static class PinTypeAdapter extends TypeAdapter<Pin> {

        final private TypeAdapter<Pin> delegateTypeAdapter;

        final private TypeAdapter<Map<String, String>> map_String__String_TypeAdapter;
        final private TypeAdapter<Map<String, User>> map_String__User_TypeAdapter;
        final private TypeAdapter<String> stringTypeAdapter;
        final private TypeAdapter<Date> dateTypeAdapter;
        final private TypeAdapter<Map<String, Object>> map_String__Object_TypeAdapter;
        final private TypeAdapter<List<PinAttributionObjects>> list_PinAttributionObjects_TypeAdapter;
        final private TypeAdapter<List<Map<String, Object>>> list_Map_String__Object__TypeAdapter;
        final private TypeAdapter<Image> imageTypeAdapter;
        final private TypeAdapter<Board> boardTypeAdapter;
        final private TypeAdapter<PinInStock> pinInStockTypeAdapter;
        final private TypeAdapter<Map<String, Integer>> map_String__Integer_TypeAdapter;

        public PinTypeAdapter(Gson gson, PinTypeAdapterFactory factory, TypeToken typeToken) {
            this.delegateTypeAdapter = gson.getDelegateAdapter(factory, typeToken);
            this.map_String__String_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, String>>(){}).nullSafe();
            this.map_String__User_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, User>>(){}).nullSafe();
            this.stringTypeAdapter = gson.getAdapter(new TypeToken<String>(){}).nullSafe();
            this.dateTypeAdapter = gson.getAdapter(new TypeToken<Date>(){}).nullSafe();
            this.map_String__Object_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, Object>>(){}).nullSafe();
            this.list_PinAttributionObjects_TypeAdapter = gson.getAdapter(new TypeToken<List<PinAttributionObjects>>(){}).nullSafe();
            this.list_Map_String__Object__TypeAdapter = gson.getAdapter(new TypeToken<List<Map<String, Object>>>(){}).nullSafe();
            this.imageTypeAdapter = gson.getAdapter(new TypeToken<Image>(){}).nullSafe();
            this.boardTypeAdapter = gson.getAdapter(new TypeToken<Board>(){}).nullSafe();
            this.pinInStockTypeAdapter = gson.getAdapter(new TypeToken<PinInStock>(){}).nullSafe();
            this.map_String__Integer_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, Integer>>(){}).nullSafe();
        }

        @Override
        public void write(JsonWriter writer, Pin value) throws IOException {
            this.delegateTypeAdapter.write(writer, value);
        }

        @Override
        public Pin read(JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = Pin.builder();
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                switch (name) {
                    case ("attribution"):
                        builder.setAttribution(map_String__String_TypeAdapter.read(reader));
                        break;
                    case ("attribution_objects"):
                        builder.setAttributionObjects(list_PinAttributionObjects_TypeAdapter.read(reader));
                        break;
                    case ("board"):
                        builder.setBoard(boardTypeAdapter.read(reader));
                        break;
                    case ("color"):
                        builder.setColor(stringTypeAdapter.read(reader));
                        break;
                    case ("counts"):
                        builder.setCounts(map_String__Integer_TypeAdapter.read(reader));
                        break;
                    case ("created_at"):
                        builder.setCreatedAt(dateTypeAdapter.read(reader));
                        break;
                    case ("creator"):
                        builder.setCreator(map_String__User_TypeAdapter.read(reader));
                        break;
                    case ("description"):
                        builder.setDescription(stringTypeAdapter.read(reader));
                        break;
                    case ("id"):
                        builder.setUid(stringTypeAdapter.read(reader));
                        break;
                    case ("image"):
                        builder.setImage(imageTypeAdapter.read(reader));
                        break;
                    case ("in_stock"):
                        builder.setInStock(pinInStockTypeAdapter.read(reader));
                        break;
                    case ("link"):
                        builder.setLink(stringTypeAdapter.read(reader));
                        break;
                    case ("media"):
                        builder.setMedia(map_String__String_TypeAdapter.read(reader));
                        break;
                    case ("note"):
                        builder.setNote(stringTypeAdapter.read(reader));
                        break;
                    case ("tags"):
                        builder.setTags(list_Map_String__Object__TypeAdapter.read(reader));
                        break;
                    case ("url"):
                        builder.setUrl(stringTypeAdapter.read(reader));
                        break;
                    case ("visual_search_attrs"):
                        builder.setVisualSearchAttrs(map_String__Object_TypeAdapter.read(reader));
                        break;
                    default:
                        reader.skipValue();
                }
            }
            reader.endObject();
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
