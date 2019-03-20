//
// Board.java
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

public class Board {

    @SerializedName("id") private @Nullable String uid;
    @SerializedName("contributors") private @Nullable Set<User> contributors;
    @SerializedName("counts") private @Nullable Map<String, Integer> counts;
    @SerializedName("created_at") private @Nullable Date createdAt;
    @SerializedName("creator") private @Nullable Map<String, String> creator;
    @SerializedName("description") private @Nullable String description;
    @SerializedName("image") private @NonNull Image image;
    @SerializedName("name") private @Nullable String name;
    @SerializedName("url") private @Nullable String url;

    static final private int ID_SET = 1 << 0;
    static final private int CONTRIBUTORS_SET = 1 << 1;
    static final private int COUNTS_SET = 1 << 2;
    static final private int CREATED_AT_SET = 1 << 3;
    static final private int CREATOR_SET = 1 << 4;
    static final private int DESCRIPTION_SET = 1 << 5;
    static final private int IMAGE_SET = 1 << 6;
    static final private int NAME_SET = 1 << 7;
    static final private int URL_SET = 1 << 8;

    private int _bits = 0;

    private Board(
        @Nullable String uid,
        @Nullable Set<User> contributors,
        @Nullable Map<String, Integer> counts,
        @Nullable Date createdAt,
        @Nullable Map<String, String> creator,
        @Nullable String description,
        @NonNull Image image,
        @Nullable String name,
        @Nullable String url,
        int _bits
    ) {
        this.uid = uid;
        this.contributors = contributors;
        this.counts = counts;
        this.createdAt = createdAt;
        this.creator = creator;
        this.description = description;
        this.image = image;
        this.name = name;
        this.url = url;
        this._bits = _bits;
    }

    public static Board.Builder builder() {
        return new Board.Builder();
    }

    public Board.Builder toBuilder() {
        return new Board.Builder(this);
    }

    public Board mergeFrom(Board model) {
        Board.Builder builder = this.toBuilder();
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
        Board that = (Board) o;
        return Objects.equals(this.uid, that.uid) &&
        Objects.equals(this.contributors, that.contributors) &&
        Objects.equals(this.counts, that.counts) &&
        Objects.equals(this.createdAt, that.createdAt) &&
        Objects.equals(this.creator, that.creator) &&
        Objects.equals(this.description, that.description) &&
        Objects.equals(this.image, that.image) &&
        Objects.equals(this.name, that.name) &&
        Objects.equals(this.url, that.url);
    }

    @Override
    public int hashCode() {
        return Objects.hash(uid,
        contributors,
        counts,
        createdAt,
        creator,
        description,
        image,
        name,
        url);
    }

    public @Nullable String getUid() {
        return this.uid;
    }

    public @Nullable Set<User> getContributors() {
        return this.contributors;
    }

    public @Nullable Map<String, Integer> getCounts() {
        return this.counts;
    }

    public @Nullable Date getCreatedAt() {
        return this.createdAt;
    }

    public @Nullable Map<String, String> getCreator() {
        return this.creator;
    }

    public @Nullable String getDescription() {
        return this.description;
    }

    public @NonNull Image getImage() {
        return this.image;
    }

    public @Nullable String getName() {
        return this.name;
    }

    public @Nullable String getUrl() {
        return this.url;
    }

    public boolean getUidIsSet() {
        return (this._bits & ID_SET) == ID_SET;
    }

    public boolean getContributorsIsSet() {
        return (this._bits & CONTRIBUTORS_SET) == CONTRIBUTORS_SET;
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

    public boolean getImageIsSet() {
        return (this._bits & IMAGE_SET) == IMAGE_SET;
    }

    public boolean getNameIsSet() {
        return (this._bits & NAME_SET) == NAME_SET;
    }

    public boolean getUrlIsSet() {
        return (this._bits & URL_SET) == URL_SET;
    }

    public static class Builder {

        @SerializedName("id") private @Nullable String uid;
        @SerializedName("contributors") private @Nullable Set<User> contributors;
        @SerializedName("counts") private @Nullable Map<String, Integer> counts;
        @SerializedName("created_at") private @Nullable Date createdAt;
        @SerializedName("creator") private @Nullable Map<String, String> creator;
        @SerializedName("description") private @Nullable String description;
        @SerializedName("image") private @NonNull Image image;
        @SerializedName("name") private @Nullable String name;
        @SerializedName("url") private @Nullable String url;

        private int _bits = 0;

        private Builder() {
        }

        private Builder(@NonNull Board model) {
            this.uid = model.uid;
            this.contributors = model.contributors;
            this.counts = model.counts;
            this.createdAt = model.createdAt;
            this.creator = model.creator;
            this.description = model.description;
            this.image = model.image;
            this.name = model.name;
            this.url = model.url;
            this._bits = model._bits;
        }

        public Builder setUid(@Nullable String value) {
            this.uid = value;
            this._bits |= ID_SET;
            return this;
        }

        public Builder setContributors(@Nullable Set<User> value) {
            this.contributors = value;
            this._bits |= CONTRIBUTORS_SET;
            return this;
        }

        public Builder setCounts(@Nullable Map<String, Integer> value) {
            this.counts = value;
            this._bits |= COUNTS_SET;
            return this;
        }

        public Builder setCreatedAt(@Nullable Date value) {
            this.createdAt = value;
            this._bits |= CREATED_AT_SET;
            return this;
        }

        public Builder setCreator(@Nullable Map<String, String> value) {
            this.creator = value;
            this._bits |= CREATOR_SET;
            return this;
        }

        public Builder setDescription(@Nullable String value) {
            this.description = value;
            this._bits |= DESCRIPTION_SET;
            return this;
        }

        public Builder setImage(@NonNull Image value) {
            this.image = value;
            this._bits |= IMAGE_SET;
            return this;
        }

        public Builder setName(@Nullable String value) {
            this.name = value;
            this._bits |= NAME_SET;
            return this;
        }

        public Builder setUrl(@Nullable String value) {
            this.url = value;
            this._bits |= URL_SET;
            return this;
        }

        public @Nullable String getUid() {
            return this.uid;
        }

        public @Nullable Set<User> getContributors() {
            return this.contributors;
        }

        public @Nullable Map<String, Integer> getCounts() {
            return this.counts;
        }

        public @Nullable Date getCreatedAt() {
            return this.createdAt;
        }

        public @Nullable Map<String, String> getCreator() {
            return this.creator;
        }

        public @Nullable String getDescription() {
            return this.description;
        }

        public @NonNull Image getImage() {
            return this.image;
        }

        public @Nullable String getName() {
            return this.name;
        }

        public @Nullable String getUrl() {
            return this.url;
        }

        public Board build() {
            return new Board(
            this.uid,
            this.contributors,
            this.counts,
            this.createdAt,
            this.creator,
            this.description,
            this.image,
            this.name,
            this.url,
            this._bits
            );
        }

        public void mergeFrom(Board model) {
            if (model.getUidIsSet()) {
                this.uid = model.uid;
            }
            if (model.getContributorsIsSet()) {
                this.contributors = model.contributors;
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
            if (model.getImageIsSet()) {
                this.image = model.image;
            }
            if (model.getNameIsSet()) {
                this.name = model.name;
            }
            if (model.getUrlIsSet()) {
                this.url = model.url;
            }
        }
    }

    public static class BoardTypeAdapterFactory implements TypeAdapterFactory {

        @Override
        public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> typeToken) {
            if (!Board.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new BoardTypeAdapter(gson, this, typeToken);
        }
    }

    public static class BoardTypeAdapter extends TypeAdapter<Board> {

        final private TypeAdapter<Board> delegateTypeAdapter;

        final private TypeAdapter<Image> imageTypeAdapter;
        final private TypeAdapter<String> stringTypeAdapter;
        final private TypeAdapter<Set<User>> set_User_TypeAdapter;
        final private TypeAdapter<Date> dateTypeAdapter;
        final private TypeAdapter<Map<String, String>> map_String__String_TypeAdapter;
        final private TypeAdapter<Map<String, Integer>> map_String__Integer_TypeAdapter;

        public BoardTypeAdapter(Gson gson, BoardTypeAdapterFactory factory, TypeToken typeToken) {
            this.delegateTypeAdapter = gson.getDelegateAdapter(factory, typeToken);
            this.imageTypeAdapter = gson.getAdapter(new TypeToken<Image>(){}).nullSafe();
            this.stringTypeAdapter = gson.getAdapter(new TypeToken<String>(){}).nullSafe();
            this.set_User_TypeAdapter = gson.getAdapter(new TypeToken<Set<User>>(){}).nullSafe();
            this.dateTypeAdapter = gson.getAdapter(new TypeToken<Date>(){}).nullSafe();
            this.map_String__String_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, String>>(){}).nullSafe();
            this.map_String__Integer_TypeAdapter = gson.getAdapter(new TypeToken<Map<String, Integer>>(){}).nullSafe();
        }

        @Override
        public void write(JsonWriter writer, Board value) throws IOException {
            this.delegateTypeAdapter.write(writer, value);
        }

        @Override
        public Board read(JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = Board.builder();
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                switch (name) {
                    case ("id"):
                        builder.setUid(stringTypeAdapter.read(reader));
                        break;
                    case ("contributors"):
                        builder.setContributors(set_User_TypeAdapter.read(reader));
                        break;
                    case ("counts"):
                        builder.setCounts(map_String__Integer_TypeAdapter.read(reader));
                        break;
                    case ("created_at"):
                        builder.setCreatedAt(dateTypeAdapter.read(reader));
                        break;
                    case ("creator"):
                        builder.setCreator(map_String__String_TypeAdapter.read(reader));
                        break;
                    case ("description"):
                        builder.setDescription(stringTypeAdapter.read(reader));
                        break;
                    case ("image"):
                        builder.setImage(imageTypeAdapter.read(reader));
                        break;
                    case ("name"):
                        builder.setName(stringTypeAdapter.read(reader));
                        break;
                    case ("url"):
                        builder.setUrl(stringTypeAdapter.read(reader));
                        break;
                    default:
                        reader.skipValue();
                }
            }
            reader.endObject();
            return builder.build();
        }
    }
}
