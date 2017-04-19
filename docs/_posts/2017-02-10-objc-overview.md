---
layout: post
title: "Model Class"
categories: objc-reference
---

#### JSON Schema to Objective-C type mapping

| Schema Property Type                | Objective-C Type                                               |
| :--- | :--- |
| Boolean                             | `BOOL`                                                     |
| Integer                             | `NSInteger`                                                      |
| Number                              | `double`                                                         |
| String Property                     | `NSString` |
| Date-time Property (String variant) | `NSDate`                                                         |
| URI Property (String variant)       | `NSURL`                                                          |
| JSON Pointer Property (`$ref`)        | ModelType                                                      |
| Array Property                      | `NSArray`                                                        |
| Array Property with Item types      | `NSArray<ModelType *>`  |
| Object Property                     | `NSDictionary`                         |
| Object Property with item types     | `NSDictionary<NSString *, ModelType *>`                          |
| Algebraic Data Type (`oneOf`)       | ADT Class (ModelType + Property name)                          |


#### Generated Methods
<pre><code class="objc">@interface User : NSObject<NSCopying, NSSecureCoding>

+ (NSString *)className;
+ (NSString *)polymorphicTypeIdentifier;

// Initialization (JSON Parsing)
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary;

// Initialization (Builder)
- (instancetype)initWithBuilder:(UserBuilder *)builder;

// Mutation
- (instancetype)copyWithBlock:(void (^)(UserBuilder *builder))block;
- (instancetype)mergeWithModel:(User *)modelObject;

// Equality
- (BOOL)isEqualToUser:(User *)anObject;

@end


</code></pre>

#### JSON Parsing
<pre><code class="objc">// Initialization
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary;
</code></pre>

The above methods (`modelObjectWithDictionary:`, `initWithModelDictionary:`) are used to instantiate an object from a dictionary representation. The implementation will use your schema definition to understand how to read the dictionary. It does this by using the keys of the `properties` definition when referencing the dictionary argument passed to these methods.

For example, if we had the schema below with the properties: `username`, `first_name`, `created_at`
<pre><code class="json">{
    "properties": {
	"username" : { "type": "string" },
	"first_name" : { "type": "string" },
	"created_at" : {
		"type": "string",
		"format": "date-time"
	}
}
</code></pre>

Then this would be the corresponding implementation for `initWithModelDictionary`.
<pre><code class="objc">
- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary
{
    if (!(self = [super init])) { return self; }
    [modelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  key, id  obj, BOOL * stop){
        if ([key isEqualToString:@"username"]) {
            id value = valueOrNil(modelDictionary, @"username");
            if (value != nil) {
                self->_username = value;
            }
            self->_userDirtyProperties.UserDirtyPropertyUsername = 1;
        }
        if ([key isEqualToString:@"first_name"]) {
            id value = valueOrNil(modelDictionary, @"first_name");
            if (value != nil) {
                self->_firstName = value;
            }
            self->_userDirtyProperties.UserDirtyPropertyFirstName = 1;
        }
        if ([key isEqualToString:@"created_at"]) {
            id value = valueOrNil(modelDictionary, @"created_at");
            if (value != nil) {
                self->_createdAt = [[NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey] transformedValue:value];
            }
            self->_userDirtyProperties.UserDirtyPropertyCreatedAt = 1;
        }
    }];
    if ([self class] == [User class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
</code></pre>

#### Date Parsing

Due to the variance of possible date formats, `NSDate` or `DateTime` objects are created using an instance of `NSValueTransformer`. It is up to the host application to register an instance of `NSValueTransformer` for the key `kPlankDateValueTransformerKey`.

- Create your own subclass of NSValueTransformer (example: `MyDateValueTransformer`)

```objc
@interface MyDateValueTransformer : NSValueTransformer
@end

@implementation MyDateValueTransformer

+ (Class)transformedValueClass
{
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO; // Optional, plank does not use this
}

- (id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
      // ... Convert NSString -> NSDate
      // ... Return the NSDate value
    };
    return nil;
}
@end
```

- Register the transformer early in your application lifecycle (likely in the app delegate)

```objc
[NSValueTransformer setValueTransformer:[MyDateValueTransformer new] forName:kPlankDateValueTransformerKey];
```

####  Tracking Set Properties

Each model instance contains a bitmask that tracks whenever a specific property has been set. This allows the model object to differentiate between `nil` and unset values when performing tasks like printing debug descriptions or merging model instances.

#### Initialization Notification

Everytime a model is initialized, a notification with the name `kPlankDidInitializeNotification` is fired with the newly created object. In addition the `userInfo` dictionary will contain additional information specifying how it was initialized. You should leverage this notification information to manage data-consistency in your application.

#### Builder Initialization

<pre><code class="objc">// Initialization (Builder)
- (instancetype)initWithBuilder:(UserBuilder *)builder;
</code></pre>

For each model there is also a builder class that is generated. The builder is a common [pattern](https://en.wikipedia.org/wiki/Builder_pattern) that we are using to create mutations of existing models. It achieves this by managing the copying of existing values and allowing the caller to specify mutations without altering the original model. The builder has a readwrite property for every property declared on the model class it creates. It can also be used to generate a model instance by itself as well.

Once we have mutated our builder objects, we can create a new model object by using `initWithBuilder:`.

<pre><code class="objc">- (instancetype)initWithBuilder:(UserBuilder *)builder
{
    if (!(self = [super init])) { return self; }
    _username = builder.username;
    _firstName = builder.firstName;
    _createdAt = builder.createdAt;
    _userDirtyProperties = builder.userDirtyProperties;
	// init notification
    return self;
}
</code></pre>


#### Serialization
<pre><code class="objc">+ (BOOL)supportsSecureCoding;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
</code></pre>

Objects generated with plank support serialization through [NSSecureCoding](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSSecureCoding_Protocol_Ref/index.html). This allows you to persist state by using `NSKeyedArchiver` and `NSKeyedUnarchiver`. Since the property types are declared in the schema, we can use `NSSecureCoding` over `NSCoding` since it requires decoding objects with their class type in addition to the key used to encode it. For example, to decode the object for `created_at` we need to specify that the value is an `NSDate`.

<pre><code class="objc">+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super init])) { return self; }
    _firstName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"first_name"];
    _createdAt = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"created_at"];
    _username = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"username"];
    _userDirtyProperties.UserDirtyPropertyFirstName = [aDecoder decodeIntForKey:@"first_name_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyCreatedAt = [aDecoder decodeIntForKey:@"created_at_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyUsername = [aDecoder decodeIntForKey:@"username_dirty_property"] & 0x1;
    // init notification
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.firstName forKey:@"first_name"];
    [aCoder encodeObject:self.createdAt forKey:@"created_at"];
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyFirstName forKey:@"first_name_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyCreatedAt forKey:@"created_at_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyUsername forKey:@"username_dirty_property"];
}
</code></pre>

#### NSCopying
<pre><code class="objc">- (id)copyWithZone:(NSZone *)zone
</code></pre>

[NSCopying](https://developer.apple.com/library/prerelease/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSCopying_Protocol/index.html) allows us to support copy operations which for immutable models can just return `self`.

<pre><code class="objc">- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
</code></pre>


#### Equality & Hashing

<pre><code class="objc">- (BOOL)isEqual:(id)anObject;
- (BOOL)isEqualToUser:(User *)anObject;
- (NSUInteger)hash;
</code></pre>

Immutable objects often need to be compared for equality. Since every mutation produces a new object, reference equality will not work so we need to rely on comparing the values of the objects themselves. Plank generates the `isEqual` and `isEqualToX:` methods where `X` is the name of your model object class. These perform a combination of reference and deep value comparisons to determine equality. In addition, the there will be an implementation of `hash` so that the objectscan be used as a key in a collection.

<pre><code class="objc">- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if ([anObject isKindOfClass:[User class]] == NO) {
        return NO;
    }
    return [self isEqualToUser:anObject];
}

- (BOOL)isEqualToUser:(User *)anObject
{
    return (
        (anObject != nil) &&
        (self == anObject) &&
        (_firstName == anObject.firstName || [_firstName isEqualToString:anObject.firstName]) &&
        (_createdAt == anObject.createdAt || [_createdAt isEqualToDate:anObject.createdAt]) &&
        (_username == anObject.username || [_username isEqualToString:anObject.username]) &&
    );
}

- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        17,
        [_firstName hash],
        [_createdAt hash],
        [_username hash],
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
</code></pre>


#### Debugging Description
<pre><code class="objc">- (NSString *)debugDescription
</code></pre>

When you're debugging, it's useful to be able to print out the value of your model. All generated classes will include an implementation for `debugDescription` which is the value that is logged when printing objects (`po objectName`) with LLDB. Without this implementation, printing an object with would just show the pointer address. The implementation will perform a shallow print of all properties that are currently set on the object.

<pre><code class="objc">- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:8];
    [descriptionFields addObject:parentDebugDescription];
    struct UserDirtyProperties props = _userDirtyProperties;
    if (props.UserDirtyPropertyFirstName) {
        [descriptionFields addObject:[@"_firstName = " stringByAppendingFormat:@"%@", _firstName]];
    }
    if (props.UserDirtyPropertyCreatedAt) {
        [descriptionFields addObject:[@"_createdAt = " stringByAppendingFormat:@"%@", _createdAt]];
    }
    if (props.UserDirtyPropertyUsername) {
        [descriptionFields addObject:[@"_username = " stringByAppendingFormat:@"%@", _username]];
    }
    return [NSString stringWithFormat:@"User = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
</code></pre>

#### Mutations

<pre><code class="objc">- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(UserBuilder *builder))block;
- (instancetype)mergeWithModel:(User *)modelObject;
</code></pre>

There are two main mutations available on every model class:

The first is `copyWithBlock` which is a [fluent interface](https://en.wikipedia.org/wiki/Fluent_interface) for mutation. This method allows you to pass a configuration block as an argument and that block will be passed a Builder object that you can safely mutate. The builder object will be used to create a new immutable model object with it's state at the end of the block.

<pre><code class="objc">- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(UserBuilder *builder))block
{
    UserBuilder *builder = [[UserBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
</code></pre>

The second is `mergeWithModel:` which is used to merge the values of the two different models. The argument is a model object that is presumed to be the most up-to-date version so it's values will be preferred when determining how to merge the two objects. The implementation differentiates between `nil` and unset properties by referencing the "dirty" properties that are tracked during initialization. This method is useful if your application progressively loads more information throughout. The implementation defers most of the merging work to it's corresponding builder class (discussed below).

<pre><code class="objc">- (instancetype)mergeWithModel:(User *)modelObject
{
    UserBuilder *builder = [[UserBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[User alloc] initWithBuilder:builder initType:initType];
}
</code></pre>

#### Usage:
- Use the `copyWithBlock` method available on the model class (modern, preferred approach)
<pre><code class="objc">// Create a model object
PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
PIPin *newPin = [pin copyWithBlock:^(PIPinBuilder *builder) {
    builder.descriptionText = @”Some new description text”;
}];
</code></pre>

- Use the builder object directly. (classic builder pattern style)
<pre><code class="objc">// Create a model object
PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
PIPinBuilder *builder = [[PIPinBuilder alloc] initWithModel:pin];
builder.descriptionText = @”Some new description text”;
PIPin *newPin = [builder build];
</code></pre>




