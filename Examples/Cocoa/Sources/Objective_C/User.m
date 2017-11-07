//
//  User.m
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

#import "Image.h"
#import "User.h"

struct UserDirtyProperties {
    unsigned int UserDirtyPropertyBio:1;
    unsigned int UserDirtyPropertyCounts:1;
    unsigned int UserDirtyPropertyCreatedAt:1;
    unsigned int UserDirtyPropertyFirstName:1;
    unsigned int UserDirtyPropertyIdentifier:1;
    unsigned int UserDirtyPropertyImage:1;
    unsigned int UserDirtyPropertyLastName:1;
    unsigned int UserDirtyPropertyUsername:1;
};

@interface User ()
@property (nonatomic, assign, readwrite) struct UserDirtyProperties userDirtyProperties;
@end

@interface UserBuilder ()
@property (nonatomic, assign, readwrite) struct UserDirtyProperties userDirtyProperties;
@end

@implementation User
+ (NSString *)className
{
    return @"User";
}
+ (NSString *)polymorphicTypeIdentifier
{
    return @"user";
}
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithModelDictionary:dictionary];
}
- (instancetype)init
{
    return [self initWithModelDictionary:@{}];
}
- (instancetype)initWithModelDictionary:(NS_VALID_UNTIL_END_OF_SCOPE NSDictionary *)modelDictionary
{
    NSParameterAssert(modelDictionary);
    if (!modelDictionary) {
        return self;
    }
    if (!(self = [super init])) {
        return self;
    }
        {
            __unsafe_unretained id value = modelDictionary[@"last_name"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_lastName = [value copy];
                }
                self->_userDirtyProperties.UserDirtyPropertyLastName = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"id"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_identifier = [value copy];
                }
                self->_userDirtyProperties.UserDirtyPropertyIdentifier = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"first_name"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_firstName = [value copy];
                }
                self->_userDirtyProperties.UserDirtyPropertyFirstName = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"image"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_image = [Image modelObjectWithDictionary:value];
                }
                self->_userDirtyProperties.UserDirtyPropertyImage = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"counts"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_counts = value;
                }
                self->_userDirtyProperties.UserDirtyPropertyCounts = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"created_at"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_createdAt = [[NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey] transformedValue:value];
                }
                self->_userDirtyProperties.UserDirtyPropertyCreatedAt = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"username"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_username = [value copy];
                }
                self->_userDirtyProperties.UserDirtyPropertyUsername = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"bio"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_bio = [value copy];
                }
                self->_userDirtyProperties.UserDirtyPropertyBio = 1;
            }
        }
    if ([self class] == [User class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (instancetype)initWithBuilder:(UserBuilder *)builder
{
    NSParameterAssert(builder);
    return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];
}
- (instancetype)initWithBuilder:(UserBuilder *)builder initType:(PlankModelInitType)initType
{
    NSParameterAssert(builder);
    if (!(self = [super init])) {
        return self;
    }
    _lastName = builder.lastName;
    _identifier = builder.identifier;
    _firstName = builder.firstName;
    _image = builder.image;
    _counts = builder.counts;
    _createdAt = builder.createdAt;
    _username = builder.username;
    _bio = builder.bio;
    _userDirtyProperties = builder.userDirtyProperties;
    if ([self class] == [User class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(initType) }];
    }
    return self;
}
- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:8];
    [descriptionFields addObject:parentDebugDescription];
    struct UserDirtyProperties props = _userDirtyProperties;
    if (props.UserDirtyPropertyLastName) {
        [descriptionFields addObject:[@"_lastName = " stringByAppendingFormat:@"%@", _lastName]];
    }
    if (props.UserDirtyPropertyIdentifier) {
        [descriptionFields addObject:[@"_identifier = " stringByAppendingFormat:@"%@", _identifier]];
    }
    if (props.UserDirtyPropertyFirstName) {
        [descriptionFields addObject:[@"_firstName = " stringByAppendingFormat:@"%@", _firstName]];
    }
    if (props.UserDirtyPropertyImage) {
        [descriptionFields addObject:[@"_image = " stringByAppendingFormat:@"%@", _image]];
    }
    if (props.UserDirtyPropertyCounts) {
        [descriptionFields addObject:[@"_counts = " stringByAppendingFormat:@"%@", _counts]];
    }
    if (props.UserDirtyPropertyCreatedAt) {
        [descriptionFields addObject:[@"_createdAt = " stringByAppendingFormat:@"%@", _createdAt]];
    }
    if (props.UserDirtyPropertyUsername) {
        [descriptionFields addObject:[@"_username = " stringByAppendingFormat:@"%@", _username]];
    }
    if (props.UserDirtyPropertyBio) {
        [descriptionFields addObject:[@"_bio = " stringByAppendingFormat:@"%@", _bio]];
    }
    return [NSString stringWithFormat:@"User = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(UserBuilder *builder))block
{
    NSParameterAssert(block);
    UserBuilder *builder = [[UserBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
- (BOOL)isEqual:(id)anObject
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
        (_lastName == anObject.lastName || [_lastName isEqualToString:anObject.lastName]) &&
        (_identifier == anObject.identifier || [_identifier isEqualToString:anObject.identifier]) &&
        (_firstName == anObject.firstName || [_firstName isEqualToString:anObject.firstName]) &&
        (_image == anObject.image || [_image isEqual:anObject.image]) &&
        (_counts == anObject.counts || [_counts isEqualToDictionary:anObject.counts]) &&
        (_createdAt == anObject.createdAt || [_createdAt isEqualToDate:anObject.createdAt]) &&
        (_username == anObject.username || [_username isEqualToString:anObject.username]) &&
        (_bio == anObject.bio || [_bio isEqualToString:anObject.bio])
    );
}
- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        17,
        [_lastName hash],
        [_identifier hash],
        [_firstName hash],
        [_image hash],
        [_counts hash],
        [_createdAt hash],
        [_username hash],
        [_bio hash]
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
- (instancetype)mergeWithModel:(User *)modelObject
{
    return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];
}
- (instancetype)mergeWithModel:(User *)modelObject initType:(PlankModelInitType)initType
{
    NSParameterAssert(modelObject);
    UserBuilder *builder = [[UserBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[User alloc] initWithBuilder:builder initType:initType];
}
- (NSDictionary *)dictionaryObjectRepresentation
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:8];
    if (_userDirtyProperties.UserDirtyPropertyLastName) {
        if (_lastName != nil) {
            [dict setObject:_lastName forKey:@"last_name"];
        } else {
            [dict setObject:[NSNull null] forKey:@"last_name"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyIdentifier) {
        if (_identifier != nil) {
            [dict setObject:_identifier forKey:@"id"];
        } else {
            [dict setObject:[NSNull null] forKey:@"id"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyFirstName) {
        if (_firstName != nil) {
            [dict setObject:_firstName forKey:@"first_name"];
        } else {
            [dict setObject:[NSNull null] forKey:@"first_name"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyImage) {
        if (_image != nil) {
            [dict setObject:[_image dictionaryObjectRepresentation] forKey:@"image"];
        } else {
            [dict setObject:[NSNull null] forKey:@"image"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyCounts) {
        if (_counts != nil) {
            [dict setObject:_counts forKey:@"counts"];
        } else {
            [dict setObject:[NSNull null] forKey:@"counts"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyCreatedAt) {
        NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey];
        if (_createdAt != nil && [[valueTransformer class] allowsReverseTransformation]) {
            [dict setObject:[valueTransformer reverseTransformedValue:_createdAt] forKey:@"created_at"];
        } else {
            [dict setObject:[NSNull null] forKey:@"created_at"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyUsername) {
        if (_username != nil) {
            [dict setObject:_username forKey:@"username"];
        } else {
            [dict setObject:[NSNull null] forKey:@"username"];
        }
    }
    if (_userDirtyProperties.UserDirtyPropertyBio) {
        if (_bio != nil) {
            [dict setObject:_bio forKey:@"bio"];
        } else {
            [dict setObject:[NSNull null] forKey:@"bio"];
        }
    }
    return dict;
}
#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
#pragma mark - NSSecureCoding
+ (BOOL)supportsSecureCoding
{
    return YES;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super init])) {
        return self;
    }
    _lastName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"last_name"];
    _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"id"];
    _firstName = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"first_name"];
    _image = [aDecoder decodeObjectOfClass:[Image class] forKey:@"image"];
    _counts = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSNumber class]]] forKey:@"counts"];
    _createdAt = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"created_at"];
    _username = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"username"];
    _bio = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"bio"];
    _userDirtyProperties.UserDirtyPropertyLastName = [aDecoder decodeIntForKey:@"last_name_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyIdentifier = [aDecoder decodeIntForKey:@"id_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyFirstName = [aDecoder decodeIntForKey:@"first_name_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyImage = [aDecoder decodeIntForKey:@"image_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyCounts = [aDecoder decodeIntForKey:@"counts_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyCreatedAt = [aDecoder decodeIntForKey:@"created_at_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyUsername = [aDecoder decodeIntForKey:@"username_dirty_property"] & 0x1;
    _userDirtyProperties.UserDirtyPropertyBio = [aDecoder decodeIntForKey:@"bio_dirty_property"] & 0x1;
    if ([self class] == [User class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.lastName forKey:@"last_name"];
    [aCoder encodeObject:self.identifier forKey:@"id"];
    [aCoder encodeObject:self.firstName forKey:@"first_name"];
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.counts forKey:@"counts"];
    [aCoder encodeObject:self.createdAt forKey:@"created_at"];
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.bio forKey:@"bio"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyLastName forKey:@"last_name_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyIdentifier forKey:@"id_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyFirstName forKey:@"first_name_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyImage forKey:@"image_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyCounts forKey:@"counts_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyCreatedAt forKey:@"created_at_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyUsername forKey:@"username_dirty_property"];
    [aCoder encodeInt:_userDirtyProperties.UserDirtyPropertyBio forKey:@"bio_dirty_property"];
}
@end

@implementation UserBuilder
- (instancetype)initWithModel:(User *)modelObject
{
    NSParameterAssert(modelObject);
    if (!(self = [super init])) {
        return self;
    }
    struct UserDirtyProperties userDirtyProperties = modelObject.userDirtyProperties;
    if (userDirtyProperties.UserDirtyPropertyLastName) {
        _lastName = modelObject.lastName;
    }
    if (userDirtyProperties.UserDirtyPropertyIdentifier) {
        _identifier = modelObject.identifier;
    }
    if (userDirtyProperties.UserDirtyPropertyFirstName) {
        _firstName = modelObject.firstName;
    }
    if (userDirtyProperties.UserDirtyPropertyImage) {
        _image = modelObject.image;
    }
    if (userDirtyProperties.UserDirtyPropertyCounts) {
        _counts = modelObject.counts;
    }
    if (userDirtyProperties.UserDirtyPropertyCreatedAt) {
        _createdAt = modelObject.createdAt;
    }
    if (userDirtyProperties.UserDirtyPropertyUsername) {
        _username = modelObject.username;
    }
    if (userDirtyProperties.UserDirtyPropertyBio) {
        _bio = modelObject.bio;
    }
    _userDirtyProperties = userDirtyProperties;
    return self;
}
- (User *)build
{
    return [[User alloc] initWithBuilder:self];
}
- (void)mergeWithModel:(User *)modelObject
{
    NSParameterAssert(modelObject);
    UserBuilder *builder = self;
    if (modelObject.userDirtyProperties.UserDirtyPropertyLastName) {
        builder.lastName = modelObject.lastName;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyIdentifier) {
        builder.identifier = modelObject.identifier;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyFirstName) {
        builder.firstName = modelObject.firstName;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyImage) {
        id value = modelObject.image;
        if (value != nil) {
            if (builder.image) {
                builder.image = [builder.image mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];
            } else {
                builder.image = value;
            }
        } else {
            builder.image = nil;
        }
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyCounts) {
        builder.counts = modelObject.counts;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyCreatedAt) {
        builder.createdAt = modelObject.createdAt;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyUsername) {
        builder.username = modelObject.username;
    }
    if (modelObject.userDirtyProperties.UserDirtyPropertyBio) {
        builder.bio = modelObject.bio;
    }
}
- (void)setLastName:(NSString *)lastName
{
    _lastName = lastName;
    _userDirtyProperties.UserDirtyPropertyLastName = 1;
}
- (void)setIdentifier:(NSString *)identifier
{
    _identifier = identifier;
    _userDirtyProperties.UserDirtyPropertyIdentifier = 1;
}
- (void)setFirstName:(NSString *)firstName
{
    _firstName = firstName;
    _userDirtyProperties.UserDirtyPropertyFirstName = 1;
}
- (void)setImage:(Image *)image
{
    _image = image;
    _userDirtyProperties.UserDirtyPropertyImage = 1;
}
- (void)setCounts:(NSDictionary<NSString *, NSNumber /* Integer */ *> *)counts
{
    _counts = counts;
    _userDirtyProperties.UserDirtyPropertyCounts = 1;
}
- (void)setCreatedAt:(NSDate *)createdAt
{
    _createdAt = createdAt;
    _userDirtyProperties.UserDirtyPropertyCreatedAt = 1;
}
- (void)setUsername:(NSString *)username
{
    _username = username;
    _userDirtyProperties.UserDirtyPropertyUsername = 1;
}
- (void)setBio:(NSString *)bio
{
    _bio = bio;
    _userDirtyProperties.UserDirtyPropertyBio = 1;
}
@end
