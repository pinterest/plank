//
// Image.java
// Autogenerated by Plank (https://pinterest.github.io/plank/)
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

package com.pinterest.models;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.gson.Gson;
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

public class Image {

    public static final String TYPE = "image";

    @SerializedName("height") private @Nullable Integer height;
    @SerializedName("url") private @Nullable String url;
    @SerializedName("width") private @Nullable Integer width;

    static final private int HEIGHT_INDEX = 0;
    static final private int URL_INDEX = 1;
    static final private int WIDTH_INDEX = 2;

    private boolean[] _bits = new boolean[3];

    private Image(
        @Nullable Integer height,
        @Nullable String url,
        @Nullable Integer width,
        boolean[] _bits
    ) {
        this.height = height;
        this.url = url;
        this.width = width;
        this._bits = _bits;
    }

    @NonNull
    public static Image.Builder builder() {
        return new Image.Builder();
    }

    @NonNull
    public Image.Builder toBuilder() {
        return new Image.Builder(this);
    }

    @NonNull
    public Image mergeFrom(@NonNull Image model) {
        Image.Builder builder = this.toBuilder();
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
        Image that = (Image) o;
        return Objects.equals(this.height, that.height) &&
        Objects.equals(this.url, that.url) &&
        Objects.equals(this.width, that.width);
    }

    @Override
    public int hashCode() {
        return Objects.hash(height,
        url,
        width);
    }

    @NonNull
    public Integer getHeight() {
        return this.height == null ? 0 : this.height;
    }

    public @Nullable String getUrl() {
        return this.url;
    }

    @NonNull
    public Integer getWidth() {
        return this.width == null ? 0 : this.width;
    }

    public boolean getHeightIsSet() {
        return this._bits.length > HEIGHT_INDEX && this._bits[HEIGHT_INDEX];
    }

    public boolean getUrlIsSet() {
        return this._bits.length > URL_INDEX && this._bits[URL_INDEX];
    }

    public boolean getWidthIsSet() {
        return this._bits.length > WIDTH_INDEX && this._bits[WIDTH_INDEX];
    }

    public static class Builder {

        private @Nullable Integer height;
        private @Nullable String url;
        private @Nullable Integer width;

        private boolean[] _bits = new boolean[3];

        private Builder() {
        }

        private Builder(@NonNull Image model) {
            this.height = model.height;
            this.url = model.url;
            this.width = model.width;
            this._bits = model._bits;
        }

        @NonNull
        public Builder setHeight(@Nullable Integer value) {
            this.height = value;
            if (this._bits.length > HEIGHT_INDEX) {
                this._bits[HEIGHT_INDEX] = true;
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
        public Builder setWidth(@Nullable Integer value) {
            this.width = value;
            if (this._bits.length > WIDTH_INDEX) {
                this._bits[WIDTH_INDEX] = true;
            }
            return this;
        }

        public @Nullable Integer getHeight() {
            return this.height;
        }

        public @Nullable String getUrl() {
            return this.url;
        }

        public @Nullable Integer getWidth() {
            return this.width;
        }

        @NonNull
        public Image build() {
            return new Image(
            this.height,
            this.url,
            this.width,
            this._bits
            );
        }

        public void mergeFrom(@NonNull Image model) {
            if (model.getHeightIsSet()) {
                this.height = model.height;
                if (this._bits.length > HEIGHT_INDEX) {
                    this._bits[HEIGHT_INDEX] = true;
                }
            }
            if (model.getUrlIsSet()) {
                this.url = model.url;
                if (this._bits.length > URL_INDEX) {
                    this._bits[URL_INDEX] = true;
                }
            }
            if (model.getWidthIsSet()) {
                this.width = model.width;
                if (this._bits.length > WIDTH_INDEX) {
                    this._bits[WIDTH_INDEX] = true;
                }
            }
        }
    }

    public static class ImageTypeAdapterFactory implements TypeAdapterFactory {

        @Nullable
        @Override
        public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
            if (!Image.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new ImageTypeAdapter(gson);
        }
    }

    public static class ImageTypeAdapter extends TypeAdapter<Image> {

        final private Gson gson;
        private TypeAdapter<Integer> integerTypeAdapter;
        private TypeAdapter<String> stringTypeAdapter;

        public ImageTypeAdapter(Gson gson) {
            this.gson = gson;
        }

        @Override
        public void write(@NonNull JsonWriter writer, Image value) throws IOException {
            if (value == null) {
                writer.nullValue();
                return;
            }
            writer.beginObject();
            if (value.getHeightIsSet()) {
                if (this.integerTypeAdapter == null) {
                    this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                }
                this.integerTypeAdapter.write(writer.name("height"), value.height);
            }
            if (value.getUrlIsSet()) {
                if (this.stringTypeAdapter == null) {
                    this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                }
                this.stringTypeAdapter.write(writer.name("url"), value.url);
            }
            if (value.getWidthIsSet()) {
                if (this.integerTypeAdapter == null) {
                    this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                }
                this.integerTypeAdapter.write(writer.name("width"), value.width);
            }
            writer.endObject();
        }

        @Nullable
        @Override
        public Image read(@NonNull JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = Image.builder();
            boolean[] bits = null;
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                switch (name) {
                    case ("height"):
                        if (this.integerTypeAdapter == null) {
                            this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                        }
                        builder.setHeight(this.integerTypeAdapter.read(reader));
                        break;
                    case ("url"):
                        if (this.stringTypeAdapter == null) {
                            this.stringTypeAdapter = this.gson.getAdapter(String.class).nullSafe();
                        }
                        builder.setUrl(this.stringTypeAdapter.read(reader));
                        break;
                    case ("width"):
                        if (this.integerTypeAdapter == null) {
                            this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                        }
                        builder.setWidth(this.integerTypeAdapter.read(reader));
                        break;
                    case ("_bits"):
                        bits = new boolean[3];
                        int i = 0;
                        reader.beginArray();
                        while (reader.hasNext() && i < 3) {
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
}
