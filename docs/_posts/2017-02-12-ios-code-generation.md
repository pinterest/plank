---
layout: post
title: "iOS Code Generation"
---

**Model Class Overview**
JSON Schema to Objective-C type mapping

| String Property                     | NSString                                                       |
| ----------------------------------- | -------------------------------------------------------------- |
| Boolean Property                    | BOOL                                                           |
| Integer Property                    | NSInteger                                                      |
| Date-time Property (String variant) | NSDate                                                         |
| Email Property (String variant)     | NSString (there isn’t a more suitable class at this time)      |
| URI Property (String variant)       | NSURL                                                          |
| JSON Pointer Property ($ref)        | ModelType                                                      |
| Array Property                      | NSArray                                                        |
| Array Property with Item types      | NSArray<ModelType *> where model type could be any other type. |
| Object Property                     | NSDictionary                                                   |
| Object Property with item types     | NSDictionary<NSString *, ModelType *>                          |


**Supported Protocols**
The protocols currently supported are [NSCopying](https://developer.apple.com/library/prerelease/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSCopying_Protocol/index.html) and [NSSecureCoding](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSSecureCoding_Protocol_Ref/index.html). NSCopying allows us to support copy operations which for immutable models will simply return **self**. NSSecureCoding allows the models to be serialized by NSCoder which can be a useful solution for data persistence. 

## Generated Methods

******Model Class**
These methods can be found in any base model class. The first four are various ways to initialize an instance of a model and the last is the api that will be used for mutation.

    + (nullable instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
    - (nullable instancetype)initWithDictionary:(NSDictionary *)modelDictionary NS_DESIGNATED_INITIALIZER;
    - (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
    - (nullable instancetype)initWithBuilder:(BuilderObjectType)builder NS_DESIGNATED_INITIALIZER;
    - (instancetype)copyWithBlock:(void (^)(BuilderObjectType builder))block;

**Builder Class**

For each model there is also a builder class that is generated. The builder is a common [pattern](https://en.wikipedia.org/wiki/Builder_pattern) that we are using to create mutations of existing models. It achieves this by managing the copying of existing values and allowing the caller to specify mutations without altering the original model. The builder has a readwrite property for every property declared on the model class it creates. It can also be used to generate a model instance by itself as well.

The first method is related to initialization and accepts an instance of the model class that is builds. The build method will take the current value of the properties defined on the builder and create a new model immutable instance.

    - (nullable instancetype)initWithModel:(ObjectType)modelObject;
    - (ObjectType)build;
## Objective-C specific generation notes

**Lightweight Generics**
The generated models/builders utilize the [lightweight generics](http://www.miqu.me/blog/2015/06/09/adopting-objectivec-generics) feature that was introduced as part of the updates to Objective-C in XCode 7. They allow the models to specify the exact types they create while keeping their interfaces generic. The declaration of lightweight generics should be done for you by the generator.

**NSValueTransformer Support**
The use of custom transformer types is currently not available and not planned for the generator. The only exception to this rule is when handling date-time property types. Because date formats can vary, the project owner is responsible for providing a NSValueTransformer subclass that will parse the date format supplied by their API. This value transformer should be registered with 
NSValueTransformer with the key “kPlankDateValueTransformerKey”.


    [NSValueTransformer setValueTransformer:[PINDateValueTransformer new]            
                                    forName:kPlankDateValueTransformerKey];

**Immutability & Mutation**
The models are currently all immutable. Immutability allows us to have many benefits with regards to safe concurrency and correctness. Often there will be a small mutation necessary (incrementing the like count, etc.) that will have to be made and the generated builder classes will help you achieve that. 
There are two primary ways to mutate a model.

1. Use the `copyWithBlock` method available on the model class (modern, preferred approach)

    // Create a model object
    PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
    PIPin *newPin = [pin copyWithBlock:^(PIPinBuilder *builder) {
                    builder.descriptionText = @”Some new description text”;
    }];

2. Use the builder object directly. (classic builder pattern style)

    // Create a model object
    PIPin *pin = [PIPin modelObjectWIthDictionary:someDictionary];
    PIPinBuilder *builder = [[PIPinBuilder alloc] initWithModel:pin];
    builder.descriptionText = @”Some new description text”;
    PIPin *newPin = [builder build];
# Migrating Models

When a new PIModel is created, we need to remove all instances of the corresponding CBLModel in the codebase. Here’s how to migrate everything over. PIPin+PIAdditions and PIPinAPIController should have examples on the following areas.

## Generated Properties

Generated properties (i.e. pin.richSummaryString) should go in the +PIAdditions category of the model.

## Collections on a model

Collections on a model (i.e. board.pins) should go in the + PIAdditions category of the model.

## Networking logic

Networking logic should go in a PIAPIController subclass (i.e. PIPinAPIController). Make sure to post a model update notification if the model is mutated by the network call

## KVO

PI* models will not respond correctly to KVO and we should remove the KVO calls. Register for model update notifications using the NSNotification+PIAdditions category methods instead.

## General Process

It can be helpful to do a Find/Replace to convert all references to the CBL* class name to the PI* one, and then migrate out needed functionality based on the errors that come up. If there are too many errors, you may also choose to pull out the CBL logic into the category and controller methods first.