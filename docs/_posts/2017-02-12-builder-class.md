---
layout: post
title: "Builder Class"
categories: objc-reference
---

<pre><code class="objc">@interface UserBuilder : NSObject
@property (nullable, nonatomic, copy, readwrite) NSString * firstName;
@property (nullable, nonatomic, strong, readwrite) NSDate * createdAt;
@property (nullable, nonatomic, copy, readwrite) NSString * username;
// Initialization
- (instancetype)initWithModel:(User *)modelObject;
// Mutation
- (User *)build;
- (void)mergeWithModel:(User *)modelObject;
@end
</code></pre>

The builder has a readwrite property for every property declared on the model class it creates. It can also be used to generate a model instance by itself as well.

The `initWithModel:` method takes an instance of the model class that is builds.

The `build` method will take the current value of the properties defined on the builder and create a new model immutable instance.

The `mergeWithModel:` method takes a model object and overwrites it's current properties for any property set on that object.