//
// OneofObject.java
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

public class OneofObject {

    public static final String TYPE = "oneof_object";

    @SerializedName("id") private @Nullable Integer uid;

    private static final int ID_INDEX = 0;

    private boolean[] _bits;

    private OneofObject(
        @Nullable Integer uid,
        boolean[] _bits
    ) {
        this.uid = uid;
        this._bits = _bits;
    }

    @NonNull
    public static OneofObject.Builder builder() {
        return new OneofObject.Builder();
    }

    @NonNull
    public OneofObject.Builder toBuilder() {
        return new OneofObject.Builder(this);
    }

    @NonNull
    public OneofObject mergeFrom(@NonNull OneofObject model) {
        OneofObject.Builder builder = this.toBuilder();
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
        OneofObject that = (OneofObject) o;
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

        private Builder(@NonNull OneofObject model) {
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
        public OneofObject build() {
            return new OneofObject(
            this.uid,
            this._bits
            );
        }

        public void mergeFrom(@NonNull OneofObject model) {
            if (model._bits.length > ID_INDEX && model._bits[ID_INDEX]) {
                this.uid = model.uid;
                this._bits[ID_INDEX] = true;
            }
        }
    }

    public static class OneofObjectTypeAdapterFactory implements TypeAdapterFactory {

        @Nullable
        @Override
        public <T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken) {
            if (!OneofObject.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new OneofObjectTypeAdapter(gson);
        }
    }

    private static class OneofObjectTypeAdapter extends TypeAdapter<OneofObject> {

        private final Gson gson;
        private TypeAdapter<Integer> integerTypeAdapter;

        OneofObjectTypeAdapter(Gson gson) {
            this.gson = gson;
        }

        @Override
        public void write(@NonNull JsonWriter writer, OneofObject value) throws IOException {
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
        public OneofObject read(@NonNull JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            Builder builder = OneofObject.builder();
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
