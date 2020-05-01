![Plank logo](https://cloud.githubusercontent.com/assets/8493/24054923/47c5d9ac-0afb-11e7-89eb-d37a58aed964.png)

# Plank
![](https://github.com/pinterest/plank/workflows/Main%20workflow%20(push)/badge.svg)

Plank is a command-line tool for generating robust immutable models from JSON Schemas. It will save you time writing boilerplate and eliminate model errors as your application scales in complexity.

We currently support the following languages:
- [Objective-C](https://pinterest.github.io/plank/docs/objc-reference/objc-overview.html)
- [Javascript (Flow)](https://pinterest.github.io/plank/docs/flow-reference/flow-overview.html)
- [Java](https://pinterest.github.io/plank/docs/java-reference/java-overview.html)

#### Schema-defined
Models are defined in JSON, a well-defined, extensible and language-independent specification.

#### Immutable Classes
Model classes are generated to be immutable. Each class provides a “Builder” class to handle mutation.

#### Type safe
Based on the type information specified in the schema definition, each class provides type validation and null reference checks to ensure model integrity.

## Installation

#### MacOS

```sh
$ brew install plank
```

#### Linux

Plank supports building in Ubuntu Linux via Docker. The Dockerfile in the repository will fetch the most recent release of plank and build dependencies including the Swift snapshot.

```sh
$ docker build -t plank .
```

#### Build from source

Plank is built using the [Swift Package Manager](https://swift.org/package-manager/). Although you’ll be able to build Plank using `swift build` directly, for distribution of the binary we’d recommend using the commands in the Makefile since they will pass the necessary flags to bundle the Swift runtime.

```sh
$ make archive
```

## Getting Started

Keep reading to learn about Plank’s features or get your try it yourself with the [tutorial](https://pinterest.github.io/plank/docs/getting-started/tutorial.html).

## Defining a schema

Plank takes a schema file as an input. Schemas are based on JSON, a well-defined, extensible and language-independent specification. Defining schemas in JSON allowed us to avoid writing unnecessary parser code and opened up the possibility of generating code from the same type system used on the server. 

```json
{
    "id": "pin.json",
    "title": "pin",
    "description" : "Schema definition of a Pin",
    "$schema": "http://json-schema.org/schema#",
    "type": "object",
    "properties": {
        "id": { "type": "string" },
        "link": { "type": "string", "format": "uri"}
    }
}
```

You’ll notice we specify the name of the model and a list of its properties. Note that link specifies an additional format attribute which tells Plank to use a more concrete type like NSURL or NSDate.

## Generating a model

Generate a schema file (`pin.json`) using Plank using the format `plank [options] file1 file2 file3 ...` 
 
```sh
$ plank pin.json
```

This will generate files (Pin.h, Pin.m) in the current directory:

```sh
$ ls
pin.json Pin.h Pin.m
```

Learn more about usage on the [installation page](https://pinterest.github.io/plank/docs/getting-started/installation.html).

## Generated Output

Plank will generate the necessary header and implementation file for your schema definition. Here is the output of the `Pin.h` header.

```objc
@interface Pin
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSURL *link;
@end
```

All properties are readonly, as this makes the class immutable. Populating instances of your model with values is performed by builder classes.

## Mutations through builders

Model mutations are performed through a builder class. The builder class is a separate type which contains readwrite properties and a build method that will create a new object. Here is the header of the builder that Plank generated for the Pin model:

```objc
@interface PinBuilder
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSURL *link;
- (Pin *)build;
@end

@interface Pin (BuilderAdditions)
- (instancetype)initWithBuilder:(PinBuilder *)builder;
@end
```

## JSON parsing

Plank will create an initializer method called `initWithModelDictionary:` that handles parsing NSDictionary objects that conform to your schema. The generated implementation will perform validation checks based on the schema’s types, avoiding the dreaded `[NSNull null]` showing up in your objects: 

```objc
@interface Pin (JSON)
- (instancetype)initWithModelDictionary:(NSDictionary *)dictionary;
@end
```

## Serialization

All Plank generated models implement methods to conform to `NSSecureCoding`, providing native serialization support out of the box.

```objc
+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (!(self = [super init])) { return self; }
    _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
    _link = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"link"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.link forKey:@"link"];
}
```

With this implementation objects are serialized using NSKeyedArchiver:

```objc
// Create a pin from a server response
Pin *pin = [[Pin alloc] initWithModelDictionary:/* server response */];
// Cache the pin
[NSKeyedArchiver archiveRootObject:pin toFile:/* cached pin path */];
// App goes on, terminates, restarts...
// Load the cached object
Pin *cachedPin = [NSKeyedUnarchiver unarchiveObjectWithFile:/* cached pin path */];
```

## Model merging and partial data

Plank models support merging and partial object materialization through a conventional “last writer wins” approach. By calling the `mergeWithModel:` on a generated model with a newer instance, the properties set on the newer instance will be preserved. To know which properties are set, the information is tracked internally within the model during initialization or through any mutation methods. In this example, an `identifier`  property is used as a primary key for object equality:

```objc
static inline id valueOrNil(NSDictionary *dict, NSString *key);
struct PinSetProperties {
  unsigned int Identifier:1;
  unsigned int Link:1;
};
- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary {
  [modelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id obj, BOOL *stop){
    if ([key isEqualToString:@"identifier"]) {
        // ... Set self.identifier
        self->_pinSetProperties.Identifier = 1;
    }
    if ([key isEqualToString:@"link"]) {
        // ... Set self.link
        self->_pinSetProperties.Link = 1;
    }
  }];
  // Post notification
  [[NSNotificationCenter defaultCenter] postNotificationName:@"kPlankModelDidInitializeNotification" object:self];
}
```

With immutable models, you have to think through how data flows through your application and how to keep a consistent state. At the end of every model class initializer, there’s a notification posted with the updated model. This is useful for integrating with your data consistency framework. With this you can track whenever a model has updated and can use internal tracking to merge the new model.

```objc
@implementation Pin(ModelMerge)
- (instancetype)mergeWithModel:(Pin *)modelObject {
    PinBuilder *builder = [[PinBuilder alloc] initWithModelObject:self];
    if (modelObject.pinSetProperties.Identifier) {
        builder.identifier = modelObject.identifier;
    }
    if (modelObject.pinSetProperties.Link) {
        builder.link = modelObject.link;
    }
    return [builder build];
}
@end
```

## Algebraic data types

Plank provides support for specifying multiple model types in a single property, commonly referred to as an Algebraic Data Type (ADT). In this example, the Pin schema receives an attribution property that will be either a User, Board, or Interest. Assume we have separate schemas defined in files user.json, board.json and interest.json, respectively.

```json
{
    "title": "pin",
    "properties": {
        "identifier": { "type": "string" },
        "link": { "type": "string", "format": "uri"},
        "attribution": {
          "oneOf": [
            { "$ref": "user.json" },
            { "$ref": "board.json" },
            { "$ref": "interest.json" }
          ]
        }
    }
}
```

Plank takes this definition of attribution and creates the necessary boilerplate code to handle each possibility. It also provides additional type-safety by generating a new class to represent your ADT.

```objc
@interface PinAttribution : NSObject<NSCopying, NSSecureCoding>
+ (instancetype)objectWithUser:(User *)user;
+ (instancetype)objectWithBoard:(Board *)board;
+ (instancetype)objectWithInterest:(Interest *)interest;
- (void)matchUser:(void (^)(User * pin))userMatchHandler
          orBoard:(void (^)(Board * board))boardMatchHandler
       orInterest:(void (^)(Interest * interest))interestMatchHandler;
@end
```

Note there’s a “match” function declared in the header. This is how you extract the true underlying value of your ADT instance. This approach guarantees at compile-time you have explicitly handled every possible case preventing bugs and reducing the needs to use runtime reflection which hinders performance. The example below shows how you’d use this match function.

```objc
PinAttribution *attribution;
[attribution matchUser:^(User *user) {
   // Do something with "user"
} orBoard:^(Board *board) {
   // Do something with "board"
} orInterest:^(Interest *interest) {
   // Do something with "interest"
}];
```

## Contributing

Pull requests for bug fixes and features welcomed.

## License

Copyright 2019 Pinterest, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
