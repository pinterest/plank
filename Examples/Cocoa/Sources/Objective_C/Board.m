//
// Board.m
// Autogenerated by Plank (https://pinterest.github.io/plank/)
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

#import "Board.h"
#import "Image.h"
#import "User.h"

struct BoardDirtyProperties {
    unsigned int BoardDirtyPropertyContributors:1;
    unsigned int BoardDirtyPropertyCounts:1;
    unsigned int BoardDirtyPropertyCreatedAt:1;
    unsigned int BoardDirtyPropertyCreator:1;
    unsigned int BoardDirtyPropertyCreatorURL:1;
    unsigned int BoardDirtyPropertyDescriptionText:1;
    unsigned int BoardDirtyPropertyImage:1;
    unsigned int BoardDirtyPropertyName:1;
    unsigned int BoardDirtyPropertyUrl:1;
};

@interface Board ()
@property (nonatomic, assign, readwrite) struct BoardDirtyProperties boardDirtyProperties;
@end

@interface BoardBuilder ()
@property (nonatomic, assign, readwrite) struct BoardDirtyProperties boardDirtyProperties;
@end

@implementation Board
+ (NSString *)className
{
    return @"Board";
}
+ (NSString *)polymorphicTypeIdentifier
{
    return @"board";
}
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithModelDictionary:dictionary];
}
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing *)error
{
    return [[self alloc] initWithModelDictionary:dictionary error:error];
}
- (instancetype)init
{
    return [self initWithModelDictionary:@{} error:NULL];
}
- (instancetype)initWithModelDictionary:(NSDictionary *)modelDictionary
{
    return [self initWithModelDictionary:modelDictionary error:NULL];
}
- (instancetype)initWithModelDictionary:(NS_VALID_UNTIL_END_OF_SCOPE NSDictionary *)modelDictionary error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(modelDictionary);
    NSParameterAssert([modelDictionary isKindOfClass:[NSDictionary class]]);
    if (!(self = [super initWithModelDictionary:modelDictionary error:error])) { return self; }
    if (!modelDictionary) {
        return self;
    }
    {
        __unsafe_unretained id value = modelDictionary[@"contributors"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyContributors = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSArray class]]) {
                    NSArray *items = value;
                    NSMutableSet *result0 = [NSMutableSet setWithCapacity:items.count];
                    for (id obj0 in items) {
                        if (obj0 != (id)kCFNull) {
                            id tmp0 = nil;
                            if (!error || [obj0 isKindOfClass:[NSDictionary class]]) {
                                tmp0 = [User modelObjectWithDictionary:obj0 error:error];
                            } else {
                                *error = PlankTypeError([@[@"contributors", @"?"] componentsJoinedByString:@"."], [NSDictionary class], [obj0 class]);
                            }
                            if (tmp0 != nil) {
                                [result0 addObject:tmp0];
                            }
                        }
                    }
                    self->_contributors = result0;
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyContributors = 0;
                    *error = PlankTypeError(@"contributors", [NSArray class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"counts"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyCounts = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSDictionary class]]) {
                    self->_counts = value;
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyCounts = 0;
                    *error = PlankTypeError(@"counts", [NSDictionary class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"created_at"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyCreatedAt = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_createdAt = [[NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey] transformedValue:value];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyCreatedAt = 0;
                    *error = PlankTypeError(@"created_at", [NSString class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"creator"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyCreator = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *items0 = value;
                    NSMutableDictionary *result0 = [NSMutableDictionary dictionaryWithCapacity:items0.count];
                    [items0 enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key0, id  _Nonnull obj0, __unused BOOL * _Nonnull stop0){
                        if (obj0 != nil && obj0 != (id)kCFNull) {
                            if (!error || [obj0 isKindOfClass:[NSString class]]) {
                                result0[key0] = [obj0 copy];
                            } else {
                                *error = PlankTypeError([@[@"creator", key0] componentsJoinedByString:@"."], [NSString class], [obj0 class]);
                            }
                        }
                    }];
                    self->_creator = result0;
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyCreator = 0;
                    *error = PlankTypeError(@"creator", [NSDictionary class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"creator_url"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyCreatorURL = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_creatorURL = [NSURL URLWithString:value];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyCreatorURL = 0;
                    *error = PlankTypeError(@"creator_url", [NSString class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"description"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyDescriptionText = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_descriptionText = [value copy];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyDescriptionText = 0;
                    *error = PlankTypeError(@"description", [NSString class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"image"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyImage = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSDictionary class]]) {
                    self->_image = [Image modelObjectWithDictionary:value error:error];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyImage = 0;
                    *error = PlankTypeError(@"image", [NSDictionary class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"name"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyName = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_name = [value copy];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyName = 0;
                    *error = PlankTypeError(@"name", [NSString class], [value class]);
                }
            }
        }
    }
    {
        __unsafe_unretained id value = modelDictionary[@"url"];
        if (value != nil) {
            self->_boardDirtyProperties.BoardDirtyPropertyUrl = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_url = [NSURL URLWithString:value];
                } else {
                    self->_boardDirtyProperties.BoardDirtyPropertyUrl = 0;
                    *error = PlankTypeError(@"url", [NSString class], [value class]);
                }
            }
        }
    }
    if ([self class] == [Board class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (instancetype)initWithBuilder:(BoardBuilder *)builder
{
    NSParameterAssert(builder);
    return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];
}
- (instancetype)initWithBuilder:(BoardBuilder *)builder initType:(PlankModelInitType)initType
{
    NSParameterAssert(builder);
    if (!(self = [super initWithBuilder:builder initType:initType])) {
        return self;
    }
    _contributors = builder.contributors;
    _counts = builder.counts;
    _createdAt = builder.createdAt;
    _creator = builder.creator;
    _creatorURL = builder.creatorURL;
    _descriptionText = builder.descriptionText;
    _image = builder.image;
    _name = builder.name;
    _url = builder.url;
    _boardDirtyProperties = builder.boardDirtyProperties;
    if ([self class] == [Board class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(initType) }];
    }
    return self;
}
#if DEBUG
- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:9];
    [descriptionFields addObject:parentDebugDescription];
    struct BoardDirtyProperties props = _boardDirtyProperties;
    if (props.BoardDirtyPropertyContributors) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_contributors = %@", _contributors]];
    }
    if (props.BoardDirtyPropertyCounts) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_counts = %@", _counts]];
    }
    if (props.BoardDirtyPropertyCreatedAt) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_createdAt = %@", _createdAt]];
    }
    if (props.BoardDirtyPropertyCreator) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_creator = %@", _creator]];
    }
    if (props.BoardDirtyPropertyCreatorURL) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_creatorURL = %@", _creatorURL]];
    }
    if (props.BoardDirtyPropertyDescriptionText) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_descriptionText = %@", _descriptionText]];
    }
    if (props.BoardDirtyPropertyImage) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_image = %@", _image]];
    }
    if (props.BoardDirtyPropertyName) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_name = %@", _name]];
    }
    if (props.BoardDirtyPropertyUrl) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_url = %@", _url]];
    }
    return [NSString stringWithFormat:@"Board = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
#endif
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(BoardBuilder *builder))block
{
    NSParameterAssert(block);
    BoardBuilder *builder = [[BoardBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if ([super isEqual:anObject] == NO) {
        return NO;
    }
    if ([anObject isKindOfClass:[Board class]] == NO) {
        return NO;
    }
    return [self isEqualToBoard:anObject];
}
- (BOOL)isEqualToBoard:(Board *)anObject
{
    return (
        (anObject != nil) &&
        ([super isEqualToModel:anObject]) &&
        (_contributors == anObject.contributors || [_contributors isEqualToSet:anObject.contributors]) &&
        (_counts == anObject.counts || [_counts isEqualToDictionary:anObject.counts]) &&
        (_createdAt == anObject.createdAt || [_createdAt isEqualToDate:anObject.createdAt]) &&
        (_creator == anObject.creator || [_creator isEqualToDictionary:anObject.creator]) &&
        (_creatorURL == anObject.creatorURL || [_creatorURL isEqual:anObject.creatorURL]) &&
        (_descriptionText == anObject.descriptionText || [_descriptionText isEqualToString:anObject.descriptionText]) &&
        (_image == anObject.image || [_image isEqual:anObject.image]) &&
        (_name == anObject.name || [_name isEqualToString:anObject.name]) &&
        (_url == anObject.url || [_url isEqual:anObject.url])
    );
}
- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        [super hash],
        [_contributors hash],
        [_counts hash],
        [_createdAt hash],
        [_creator hash],
        [_creatorURL hash],
        [_descriptionText hash],
        [_image hash],
        [_name hash],
        [_url hash]
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
- (instancetype)mergeWithModel:(Board *)modelObject
{
    return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];
}
- (instancetype)mergeWithModel:(Board *)modelObject initType:(PlankModelInitType)initType
{
    NSParameterAssert(modelObject);
    BoardBuilder *builder = [[BoardBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[Board alloc] initWithBuilder:builder initType:initType];
}
- (NSDictionary *)dictionaryObjectRepresentation
{
    NSMutableDictionary *dict = [[super dictionaryObjectRepresentation] mutableCopy];
    if (_boardDirtyProperties.BoardDirtyPropertyContributors) {
        if (_contributors != nil) {
            __auto_type items0 = _contributors;
            NSMutableArray *result0 = [NSMutableArray arrayWithCapacity:items0.count];
            for (User * obj0 in items0) {
                [result0 addObject:[obj0 dictionaryObjectRepresentation]];
            }
            [dict setObject:result0 forKey:@"contributors"];
        } else {
            [dict setObject:[NSNull null] forKey:@"contributors"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyCounts) {
        if (_counts != nil) {
            [dict setObject:_counts forKey:@"counts"];
        } else {
            [dict setObject:[NSNull null] forKey:@"counts"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyCreatedAt) {
        if (_createdAt != nil) {
            NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey];
            if ([[valueTransformer class] allowsReverseTransformation]) {
                [dict setObject:[valueTransformer reverseTransformedValue:_createdAt] forKey:@"created_at"];
            } else {
                [dict setObject:[NSNull null] forKey:@"created_at"];
            }
        } else {
            [dict setObject:[NSNull null] forKey:@"created_at"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyCreator) {
        if (_creator != nil) {
            [dict setObject:_creator forKey:@"creator"];
        } else {
            [dict setObject:[NSNull null] forKey:@"creator"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyCreatorURL) {
        if (_creatorURL != nil) {
            [dict setObject:[_creatorURL absoluteString] forKey:@"creator_url"];
        } else {
            [dict setObject:[NSNull null] forKey:@"creator_url"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyDescriptionText) {
        if (_descriptionText != nil) {
            [dict setObject:_descriptionText forKey:@"description"];
        } else {
            [dict setObject:[NSNull null] forKey:@"description"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyImage) {
        if (_image != nil) {
            [dict setObject:[_image dictionaryObjectRepresentation] forKey:@"image"];
        } else {
            [dict setObject:[NSNull null] forKey:@"image"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyName) {
        if (_name != nil) {
            [dict setObject:_name forKey:@"name"];
        } else {
            [dict setObject:[NSNull null] forKey:@"name"];
        }
    }
    if (_boardDirtyProperties.BoardDirtyPropertyUrl) {
        if (_url != nil) {
            [dict setObject:[_url absoluteString] forKey:@"url"];
        } else {
            [dict setObject:[NSNull null] forKey:@"url"];
        }
    }
    return dict;
}
- (BOOL)isContributorsSet
{
    return _boardDirtyProperties.BoardDirtyPropertyContributors == 1;
}
- (BOOL)isCountsSet
{
    return _boardDirtyProperties.BoardDirtyPropertyCounts == 1;
}
- (BOOL)isCreatedAtSet
{
    return _boardDirtyProperties.BoardDirtyPropertyCreatedAt == 1;
}
- (BOOL)isCreatorSet
{
    return _boardDirtyProperties.BoardDirtyPropertyCreator == 1;
}
- (BOOL)isCreatorUrlSet
{
    return _boardDirtyProperties.BoardDirtyPropertyCreatorURL == 1;
}
- (BOOL)isDescriptionTextSet
{
    return _boardDirtyProperties.BoardDirtyPropertyDescriptionText == 1;
}
- (BOOL)isImageSet
{
    return _boardDirtyProperties.BoardDirtyPropertyImage == 1;
}
- (BOOL)isNameSet
{
    return _boardDirtyProperties.BoardDirtyPropertyName == 1;
}
- (BOOL)isUrlSet
{
    return _boardDirtyProperties.BoardDirtyPropertyUrl == 1;
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
    if (!(self = [super initWithCoder:aDecoder])) { return self; }
    _contributors = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSSet class], [User class]]] forKey:@"contributors"];
    _counts = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSNumber class]]] forKey:@"counts"];
    _createdAt = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"created_at"];
    _creator = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSString class]]] forKey:@"creator"];
    _creatorURL = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"creator_url"];
    _descriptionText = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"description"];
    _image = [aDecoder decodeObjectOfClass:[Image class] forKey:@"image"];
    _name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
    _url = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"];
    _boardDirtyProperties.BoardDirtyPropertyContributors = [aDecoder decodeIntForKey:@"contributors_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyCounts = [aDecoder decodeIntForKey:@"counts_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyCreatedAt = [aDecoder decodeIntForKey:@"created_at_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyCreator = [aDecoder decodeIntForKey:@"creator_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyCreatorURL = [aDecoder decodeIntForKey:@"creator_url_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyDescriptionText = [aDecoder decodeIntForKey:@"description_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyImage = [aDecoder decodeIntForKey:@"image_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyName = [aDecoder decodeIntForKey:@"name_dirty_property"] & 0x1;
    _boardDirtyProperties.BoardDirtyPropertyUrl = [aDecoder decodeIntForKey:@"url_dirty_property"] & 0x1;
    if ([self class] == [Board class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.contributors forKey:@"contributors"];
    [aCoder encodeObject:self.counts forKey:@"counts"];
    [aCoder encodeObject:self.createdAt forKey:@"created_at"];
    [aCoder encodeObject:self.creator forKey:@"creator"];
    [aCoder encodeObject:self.creatorURL forKey:@"creator_url"];
    [aCoder encodeObject:self.descriptionText forKey:@"description"];
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyContributors forKey:@"contributors_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyCounts forKey:@"counts_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyCreatedAt forKey:@"created_at_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyCreator forKey:@"creator_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyCreatorURL forKey:@"creator_url_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyDescriptionText forKey:@"description_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyImage forKey:@"image_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyName forKey:@"name_dirty_property"];
    [aCoder encodeInt:_boardDirtyProperties.BoardDirtyPropertyUrl forKey:@"url_dirty_property"];
}
@end

@implementation BoardBuilder
- (instancetype)initWithModel:(Board *)modelObject
{
    NSParameterAssert(modelObject);
    if (!(self = [super initWithModel:modelObject])) { return self; }
    struct BoardDirtyProperties boardDirtyProperties = modelObject.boardDirtyProperties;
    if (boardDirtyProperties.BoardDirtyPropertyContributors) {
        _contributors = modelObject.contributors;
    }
    if (boardDirtyProperties.BoardDirtyPropertyCounts) {
        _counts = modelObject.counts;
    }
    if (boardDirtyProperties.BoardDirtyPropertyCreatedAt) {
        _createdAt = modelObject.createdAt;
    }
    if (boardDirtyProperties.BoardDirtyPropertyCreator) {
        _creator = modelObject.creator;
    }
    if (boardDirtyProperties.BoardDirtyPropertyCreatorURL) {
        _creatorURL = modelObject.creatorURL;
    }
    if (boardDirtyProperties.BoardDirtyPropertyDescriptionText) {
        _descriptionText = modelObject.descriptionText;
    }
    if (boardDirtyProperties.BoardDirtyPropertyImage) {
        _image = modelObject.image;
    }
    if (boardDirtyProperties.BoardDirtyPropertyName) {
        _name = modelObject.name;
    }
    if (boardDirtyProperties.BoardDirtyPropertyUrl) {
        _url = modelObject.url;
    }
    _boardDirtyProperties = boardDirtyProperties;
    return self;
}
- (Board *)build
{
    return [[Board alloc] initWithBuilder:self];
}
- (void)mergeWithModel:(Board *)modelObject
{
    NSParameterAssert(modelObject);
    [super mergeWithModel:modelObject];
    BoardBuilder *builder = self;
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyContributors) {
        builder.contributors = modelObject.contributors;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyCounts) {
        builder.counts = modelObject.counts;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyCreatedAt) {
        builder.createdAt = modelObject.createdAt;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyCreator) {
        builder.creator = modelObject.creator;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyCreatorURL) {
        builder.creatorURL = modelObject.creatorURL;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyDescriptionText) {
        builder.descriptionText = modelObject.descriptionText;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyImage) {
        id value = modelObject.image;
        if (builder.image) {
            builder.image = [builder.image mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];
        } else {
            builder.image = value;
        }
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyName) {
        builder.name = modelObject.name;
    }
    if (modelObject.boardDirtyProperties.BoardDirtyPropertyUrl) {
        builder.url = modelObject.url;
    }
}
- (void)setContributors:(NSSet<User *> *)contributors
{
    _contributors = contributors;
    _boardDirtyProperties.BoardDirtyPropertyContributors = 1;
}
- (void)setCounts:(NSDictionary<NSString *, NSNumber /* Integer */ *> *)counts
{
    _counts = counts;
    _boardDirtyProperties.BoardDirtyPropertyCounts = 1;
}
- (void)setCreatedAt:(NSDate *)createdAt
{
    _createdAt = [createdAt copy];
    _boardDirtyProperties.BoardDirtyPropertyCreatedAt = 1;
}
- (void)setCreator:(NSDictionary<NSString *, NSString *> *)creator
{
    _creator = creator;
    _boardDirtyProperties.BoardDirtyPropertyCreator = 1;
}
- (void)setCreatorURL:(NSURL *)creatorURL
{
    _creatorURL = [creatorURL copy];
    _boardDirtyProperties.BoardDirtyPropertyCreatorURL = 1;
}
- (void)setDescriptionText:(NSString *)descriptionText
{
    _descriptionText = [descriptionText copy];
    _boardDirtyProperties.BoardDirtyPropertyDescriptionText = 1;
}
- (void)setImage:(Image *)image
{
    _image = image;
    _boardDirtyProperties.BoardDirtyPropertyImage = 1;
}
- (void)setName:(NSString *)name
{
    _name = [name copy];
    _boardDirtyProperties.BoardDirtyPropertyName = 1;
}
- (void)setUrl:(NSURL *)url
{
    _url = [url copy];
    _boardDirtyProperties.BoardDirtyPropertyUrl = 1;
}
@end
