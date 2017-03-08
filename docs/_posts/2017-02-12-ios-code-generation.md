---
layout: post
title: "Objective-C Reference"
---

## Model Class Overview
JSON Schema to Objective-C type mapping

| Schema Property Type                | Objective-C Type                                               |
| :--- | :--- |
| String                              | `NSString`                                                       |
| Boolean                             | `BOOL`                                                     |
| Integer                             | `NSInteger`                                                      |
| Number                              | `double`                                                         |
| Date-time Property (String variant) | `NSDate`                                                         |
| String Property                     | `NSString` |
| URI Property (String variant)       | `NSURL`                                                          |
| JSON Pointer Property (`$ref`)        | ModelType                                                      |
| Array Property                      | `NSArray`                                                        |
| Array Property with Item types      | `NSArray<ModelType *>`  |
| Object Property                     | `NSDictionary`                         |
| Object Property with item types     | `NSDictionary<NSString *, ModelType *>`                          |
| Algebraic Data Type (`oneOf`)       | ADT Class (ModelType + Property name)                          |


## Supported Protocols
The protocols currently supported are [NSCopying](https://developer.apple.com/library/prerelease/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSCopying_Protocol/index.html) and [NSSecureCoding](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSSecureCoding_Protocol_Ref/index.html). NSCopying allows us to support copy operations which for immutable models will simply return **self**. NSSecureCoding allows the models to be serialized by NSCoder which can be a useful solution for data persistence.

## Generated Methods


### Model Class

These methods can be found in any base model class. The first four are various ways to initialize an instance of a model and the last is the api that will be used for mutation.

{% highlight objc %}
+ (nullable instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
- (nullable instancetype)initWithDictionary:(NSDictionary *)modelDictionary NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithBuilder:(BuilderObjectType)builder NS_DESIGNATED_INITIALIZER;
- (instancetype)copyWithBlock:(void (^)(BuilderObjectType builder))block;
{% endhighlight %}

### Builder Class

For each model there is also a builder class that is generated. The builder is a common [pattern](https://en.wikipedia.org/wiki/Builder_pattern) that we are using to create mutations of existing models. It achieves this by managing the copying of existing values and allowing the caller to specify mutations without altering the original model. The builder has a readwrite property for every property declared on the model class it creates. It can also be used to generate a model instance by itself as well.

The first method is related to initialization and accepts an instance of the model class that is builds. The build method will take the current value of the properties defined on the builder and create a new model immutable instance.

{% highlight objc %}
- (nullable instancetype)initWithModel:(ObjectType)modelObject;
- (ObjectType)build;
{% endhighlight %}

## Objective-C specific generation notes

**NSValueTransformer Support**
The use of custom transformer types is currently not available and not planned for the generator. The only exception to this rule is when handling date-time property types. Because date formats can vary, the project owner is responsible for providing a NSValueTransformer subclass that will parse the date format supplied by their API. This value transformer should be registered with
NSValueTransformer with the key “kPlankDateValueTransformerKey”.



**Immutability & Mutation**
The models are currently all immutable. Immutability allows us to have many benefits with regards to safe concurrency and correctness. Often there will be a small mutation necessary (incrementing the like count, etc.) that will have to be made and the generated builder classes will help you achieve that.
There are two primary ways to mutate a model.

- Use the `copyWithBlock` method available on the model class (modern, preferred approach)
{% highlight objc %}
// Create a model object
PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
PIPin *newPin = [pin copyWithBlock:^(PIPinBuilder *builder) {
                builder.descriptionText = @”Some new description text”;
}];
{% endhighlight %}

- Use the builder object directly. (classic builder pattern style)
{% highlight objc %}
// Create a model object
PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
PIPinBuilder *builder = [[PIPinBuilder alloc] initWithModel:pin];
builder.descriptionText = @”Some new description text”;
PIPin *newPin = [builder build];
{% endhighlight %}
