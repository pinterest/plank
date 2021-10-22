//
// Nested.java
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
import java.util.Objects;

/**
 * Autogenerated by Plank (https://pinterest.github.io/plank/)
 * DO NOT EDIT - EDITS WILL BE OVERWRITTEN
**/
public class Nested {

    public static final String TYPE = "nested";

    @SerializedName("id") private @Nullable Integer uid;

    private static final int ID_INDEX = 0;

    private boolean[] _bits;

    public Nested() {
        this._bits = new boolean[1];
    }

    private Nested(
        @Nullable Integer uid,
        boolean[] _bits
    ) {
        this.uid = uid;
        this._bits = _bits;
    }

    @NonNull
    public static Nested.Builder builder() {
        return new Nested.Builder();
    }

    @NonNull
    public Nested.Builder toBuilder() {
        return new Nested.Builder(this);
    }

    @NonNull
    public Nested mergeFrom(@NonNull Nested model) {
        if (this == model) {
            return this;
        }
        Nested.Builder builder = this.toBuilder();
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
        Nested that = (Nested) o;
        return Objects.equals(this.uid, that.uid);
    }

    @Override
    public int hashCode() {
        return Objects.hash(uid);
    }

    @NonNull
    public Integer getUid() {
        return this.uid == null ? 0 : this.uid;
    }

    public boolean getUidIsSet() {
        return this._bits.length > ID_INDEX && this._bits[ID_INDEX];
    }

    public static class Builder {

        private @Nullable Integer uid;

        private boolean[] _bits;

        private Builder() {
            this._bits = new boolean[1];
        }

        private Builder(@NonNull Nested model) {
            this.uid = model.uid;
            this._bits = model._bits;
        }

        @NonNull
        public Builder setUid(@Nullable Integer value) {
            this.uid = value;
            if (this._bits.length > ID_INDEX) {
                this._bits[ID_INDEX] = true;
            }
            return this;
        }

        public @Nullable Integer getUid() {
            return this.uid;
        }

        @NonNull
        public Nested build() {
            return new Nested(
            this.uid,
            this._bits
            );
        }

        public void mergeFrom(@NonNull Nested model) {
            if (model._bits.length > ID_INDEX && model._bits[ID_INDEX]) {
                this.uid = model.uid;
                this._bits[ID_INDEX] = true;
            }
        }
    }

    public static class NestedTypeAdapterFactory implements TypeAdapterFactory {

        @Nullable
        @Override
        public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
            if (!Nested.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new NestedTypeAdapter(gson);
        }
    }

    private static class NestedTypeAdapter extends TypeAdapter<Nested> {

        private final Gson gson;
        private TypeAdapter<Integer> integerTypeAdapter;

        NestedTypeAdapter(Gson gson) {
            this.gson = gson;
        }

        @Override
        public void write(@NonNull JsonWriter writer, Nested value) throws IOException {
            if (value == null) {
                writer.nullValue();
                return;
            }
            writer.beginObject();
            if (value._bits.length > ID_INDEX && value._bits[ID_INDEX]) {
                if (this.integerTypeAdapter == null) {
                    this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                }
                this.integerTypeAdapter.write(writer.name("id"), value.uid);
            }
            writer.endObject();
        }

        @Nullable
        @Override
        public Nested read(@NonNull JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = Nested.builder();
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                switch (name) {
                    case ("id"):
                        if (this.integerTypeAdapter == null) {
                            this.integerTypeAdapter = this.gson.getAdapter(Integer.class).nullSafe();
                        }
                        builder.setUid(this.integerTypeAdapter.read(reader));
                        break;
                    default:
                        reader.skipValue();
                        break;
                }
            }
            reader.endObject();
            return builder.build();
        }
    }
}
