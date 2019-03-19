//
// Model.java
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

public class Model {

    @SerializedName("id") private @Nullable String identifier;

    static final private int ID_SET = 1 << 0;

    private int _bits = 0;

    private Model(
        @Nullable String identifier,
        int _bits
    ) {
        this.identifier = identifier;
        this._bits = _bits;
    }

    public static Model.Builder builder() {
        return new Model.Builder();
    }

    public Model.Builder toBuilder() {
        return new Model.Builder(this);
    }

    public Model mergeFrom(Model model) {
        Model.Builder builder = this.toBuilder();
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
        Model that = (Model) o;
        return Objects.equals(this.identifier, that.identifier);
    }

    @Override
    public int hashCode() {
        return Objects.hash(identifier);
    }

    public @Nullable String getIdentifier() {
        return this.identifier;
    }

    public boolean getIdentifierIsSet() {
        return (this._bits & ID_SET) == ID_SET;
    }

    public static class Builder {

        @SerializedName("id") private @Nullable String identifier;

        private int _bits = 0;

        private Builder() {
        }

        private Builder(@NonNull Model model) {
            this.identifier = model.identifier;
            this._bits = model._bits;
        }

        public Builder setIdentifier(@Nullable String value) {
            this.identifier = value;
            this._bits |= ID_SET;
            return this;
        }

        public @Nullable String getIdentifier() {
            return this.identifier;
        }

        public Model build() {
            return new Model(
            this.identifier,
            this._bits
            );
        }

        public void mergeFrom(Model model) {
            if (model.getIdentifierIsSet()) {
                this.identifier = model.identifier;
            }
        }
    }

    public static class ModelTypeAdapterFactory implements TypeAdapterFactory {

        @Override
        public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> typeToken) {
            if (!Model.class.isAssignableFrom(typeToken.getRawType())) {
                return null;
            }
            return (TypeAdapter<T>) new ModelTypeAdapter(gson, this, typeToken);
        }
    }

    public static class ModelTypeAdapter extends TypeAdapter<Model> {

        final private TypeAdapter<Model> delegateTypeAdapter;
        final private TypeAdapter<JsonElement> elementTypeAdapter;

        public ModelTypeAdapter(Gson gson, ModelTypeAdapterFactory factory, TypeToken typeToken) {
            this.delegateTypeAdapter = gson.getDelegateAdapter(factory, typeToken);
            this.elementTypeAdapter = gson.getAdapter(JsonElement.class);
        }

        @Override
        public void write(JsonWriter writer, Model value) throws IOException {
            this.delegateTypeAdapter.write(writer, value);
        }

        @Override
        public Model read(JsonReader reader) throws IOException {
            if (reader.peek() == JsonToken.NULL) {
                reader.nextNull();
                return null;
            }
            JsonElement tree = this.elementTypeAdapter.read(reader);
            Model model = this.delegateTypeAdapter.fromJsonTree(tree);
            Set<String> keys = tree.getAsJsonObject().keySet();
            for (String key : keys) {
                switch (key) {
                    case ("id"):
                        model._bits |= ID_SET;
                        break;
                    default:
                        break;
                }
            }
            return model;
        }
    }
}
