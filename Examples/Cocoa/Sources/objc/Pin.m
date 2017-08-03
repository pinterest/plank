//
//  Pin.m
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

#import "Board.h"
#import "Image.h"
#import "Pin.h"
#import "User.h"

struct PinDirtyProperties {
    unsigned int PinDirtyPropertyAttribution:1;
    unsigned int PinDirtyPropertyBoard:1;
    unsigned int PinDirtyPropertyColor:1;
    unsigned int PinDirtyPropertyCounts:1;
    unsigned int PinDirtyPropertyCreatedAt:1;
    unsigned int PinDirtyPropertyCreator:1;
    unsigned int PinDirtyPropertyDescriptionText:1;
    unsigned int PinDirtyPropertyIdentifier:1;
    unsigned int PinDirtyPropertyImage:1;
    unsigned int PinDirtyPropertyLink:1;
    unsigned int PinDirtyPropertyMedia:1;
    unsigned int PinDirtyPropertyNote:1;
    unsigned int PinDirtyPropertyUrl:1;
};

@interface Pin ()
@property (nonatomic, assign, readwrite) struct PinDirtyProperties pinDirtyProperties;
@end

@interface PinBuilder ()
@property (nonatomic, assign, readwrite) struct PinDirtyProperties pinDirtyProperties;
@end

@implementation Pin
+ (NSString *)className
{
    return @"Pin";
}
+ (NSString *)polymorphicTypeIdentifier
{
    return @"pin";
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
    if (!(self = [super init])) {
        return self;
    }
        {
            __unsafe_unretained id value = modelDictionary[@"note"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_note = [value copy];
                }
                self->_pinDirtyProperties.PinDirtyPropertyNote = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"media"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    NSDictionary *items0 = value;
                    NSMutableDictionary *result0 = [NSMutableDictionary dictionaryWithCapacity:items0.count];
                    [items0 enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key0, id  _Nonnull obj0, __unused BOOL * _Nonnull stop0){
                        if (obj0 != nil && obj0 != (id)kCFNull) {
                            result0[key0] = [obj0 copy];
                        }
                    }];
                    self->_media = result0;
                }
                self->_pinDirtyProperties.PinDirtyPropertyMedia = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"counts"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_counts = value;
                }
                self->_pinDirtyProperties.PinDirtyPropertyCounts = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"description"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_descriptionText = [value copy];
                }
                self->_pinDirtyProperties.PinDirtyPropertyDescriptionText = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"creator"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    NSDictionary *items0 = value;
                    NSMutableDictionary *result0 = [NSMutableDictionary dictionaryWithCapacity:items0.count];
                    [items0 enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key0, id  _Nonnull obj0, __unused BOOL * _Nonnull stop0){
                        if (obj0 != nil && obj0 != (id)kCFNull) {
                            result0[key0] = [User modelObjectWithDictionary:obj0];
                        }
                    }];
                    self->_creator = result0;
                }
                self->_pinDirtyProperties.PinDirtyPropertyCreator = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"attribution"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    NSDictionary *items0 = value;
                    NSMutableDictionary *result0 = [NSMutableDictionary dictionaryWithCapacity:items0.count];
                    [items0 enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key0, id  _Nonnull obj0, __unused BOOL * _Nonnull stop0){
                        if (obj0 != nil && obj0 != (id)kCFNull) {
                            result0[key0] = [obj0 copy];
                        }
                    }];
                    self->_attribution = result0;
                }
                self->_pinDirtyProperties.PinDirtyPropertyAttribution = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"board"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_board = [Board modelObjectWithDictionary:value];
                }
                self->_pinDirtyProperties.PinDirtyPropertyBoard = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"color"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_color = [value copy];
                }
                self->_pinDirtyProperties.PinDirtyPropertyColor = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"link"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_link = [NSURL URLWithString:value];
                }
                self->_pinDirtyProperties.PinDirtyPropertyLink = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"id"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_identifier = [value copy];
                }
                self->_pinDirtyProperties.PinDirtyPropertyIdentifier = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"image"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_image = [Image modelObjectWithDictionary:value];
                }
                self->_pinDirtyProperties.PinDirtyPropertyImage = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"created_at"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_createdAt = [[NSValueTransformer valueTransformerForName:kPlankDateValueTransformerKey] transformedValue:value];
                }
                self->_pinDirtyProperties.PinDirtyPropertyCreatedAt = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"url"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_url = [NSURL URLWithString:value];
                }
                self->_pinDirtyProperties.PinDirtyPropertyUrl = 1;
            }
        }
    if ([self class] == [Pin class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (instancetype)initWithBuilder:(PinBuilder *)builder
{
    NSParameterAssert(builder);
    return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];
}
- (instancetype)initWithBuilder:(PinBuilder *)builder initType:(PlankModelInitType)initType
{
    NSParameterAssert(builder);
    if (!(self = [super init])) {
        return self;
    }
    _note = builder.note;
    _media = builder.media;
    _counts = builder.counts;
    _descriptionText = builder.descriptionText;
    _creator = builder.creator;
    _attribution = builder.attribution;
    _board = builder.board;
    _color = builder.color;
    _link = builder.link;
    _identifier = builder.identifier;
    _image = builder.image;
    _createdAt = builder.createdAt;
    _url = builder.url;
    _pinDirtyProperties = builder.pinDirtyProperties;
    if ([self class] == [Pin class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(initType) }];
    }
    return self;
}
- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:13];
    [descriptionFields addObject:parentDebugDescription];
    struct PinDirtyProperties props = _pinDirtyProperties;
    if (props.PinDirtyPropertyNote) {
        [descriptionFields addObject:[@"_note = " stringByAppendingFormat:@"%@", _note]];
    }
    if (props.PinDirtyPropertyMedia) {
        [descriptionFields addObject:[@"_media = " stringByAppendingFormat:@"%@", _media]];
    }
    if (props.PinDirtyPropertyCounts) {
        [descriptionFields addObject:[@"_counts = " stringByAppendingFormat:@"%@", _counts]];
    }
    if (props.PinDirtyPropertyDescriptionText) {
        [descriptionFields addObject:[@"_descriptionText = " stringByAppendingFormat:@"%@", _descriptionText]];
    }
    if (props.PinDirtyPropertyCreator) {
        [descriptionFields addObject:[@"_creator = " stringByAppendingFormat:@"%@", _creator]];
    }
    if (props.PinDirtyPropertyAttribution) {
        [descriptionFields addObject:[@"_attribution = " stringByAppendingFormat:@"%@", _attribution]];
    }
    if (props.PinDirtyPropertyBoard) {
        [descriptionFields addObject:[@"_board = " stringByAppendingFormat:@"%@", _board]];
    }
    if (props.PinDirtyPropertyColor) {
        [descriptionFields addObject:[@"_color = " stringByAppendingFormat:@"%@", _color]];
    }
    if (props.PinDirtyPropertyLink) {
        [descriptionFields addObject:[@"_link = " stringByAppendingFormat:@"%@", _link]];
    }
    if (props.PinDirtyPropertyIdentifier) {
        [descriptionFields addObject:[@"_identifier = " stringByAppendingFormat:@"%@", _identifier]];
    }
    if (props.PinDirtyPropertyImage) {
        [descriptionFields addObject:[@"_image = " stringByAppendingFormat:@"%@", _image]];
    }
    if (props.PinDirtyPropertyCreatedAt) {
        [descriptionFields addObject:[@"_createdAt = " stringByAppendingFormat:@"%@", _createdAt]];
    }
    if (props.PinDirtyPropertyUrl) {
        [descriptionFields addObject:[@"_url = " stringByAppendingFormat:@"%@", _url]];
    }
    return [NSString stringWithFormat:@"Pin = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(PinBuilder *builder))block
{
    NSParameterAssert(block);
    PinBuilder *builder = [[PinBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if ([anObject isKindOfClass:[Pin class]] == NO) {
        return NO;
    }
    return [self isEqualToPin:anObject];
}
- (BOOL)isEqualToPin:(Pin *)anObject
{
    return (
        (anObject != nil) &&
        (_note == anObject.note || [_note isEqualToString:anObject.note]) &&
        (_media == anObject.media || [_media isEqualToDictionary:anObject.media]) &&
        (_counts == anObject.counts || [_counts isEqualToDictionary:anObject.counts]) &&
        (_descriptionText == anObject.descriptionText || [_descriptionText isEqualToString:anObject.descriptionText]) &&
        (_creator == anObject.creator || [_creator isEqualToDictionary:anObject.creator]) &&
        (_attribution == anObject.attribution || [_attribution isEqualToDictionary:anObject.attribution]) &&
        (_board == anObject.board || [_board isEqual:anObject.board]) &&
        (_color == anObject.color || [_color isEqualToString:anObject.color]) &&
        (_link == anObject.link || [_link isEqual:anObject.link]) &&
        (_identifier == anObject.identifier || [_identifier isEqualToString:anObject.identifier]) &&
        (_image == anObject.image || [_image isEqual:anObject.image]) &&
        (_createdAt == anObject.createdAt || [_createdAt isEqualToDate:anObject.createdAt]) &&
        (_url == anObject.url || [_url isEqual:anObject.url])
    );
}
- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        17,
        [_note hash],
        [_media hash],
        [_counts hash],
        [_descriptionText hash],
        [_creator hash],
        [_attribution hash],
        [_board hash],
        [_color hash],
        [_link hash],
        [_identifier hash],
        [_image hash],
        [_createdAt hash],
        [_url hash]
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
- (instancetype)mergeWithModel:(Pin *)modelObject
{
    return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];
}
- (instancetype)mergeWithModel:(Pin *)modelObject initType:(PlankModelInitType)initType
{
    NSParameterAssert(modelObject);
    PinBuilder *builder = [[PinBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[Pin alloc] initWithBuilder:builder initType:initType];
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
    _note = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"note"];
    _media = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSString class]]] forKey:@"media"];
    _counts = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSNumber class]]] forKey:@"counts"];
    _descriptionText = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"description"];
    _creator = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [User class]]] forKey:@"creator"];
    _attribution = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSString class]]] forKey:@"attribution"];
    _board = [aDecoder decodeObjectOfClass:[Board class] forKey:@"board"];
    _color = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"color"];
    _link = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"link"];
    _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"id"];
    _image = [aDecoder decodeObjectOfClass:[Image class] forKey:@"image"];
    _createdAt = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"created_at"];
    _url = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"];
    _pinDirtyProperties.PinDirtyPropertyNote = [aDecoder decodeIntForKey:@"note_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyMedia = [aDecoder decodeIntForKey:@"media_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyCounts = [aDecoder decodeIntForKey:@"counts_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyDescriptionText = [aDecoder decodeIntForKey:@"description_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyCreator = [aDecoder decodeIntForKey:@"creator_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyAttribution = [aDecoder decodeIntForKey:@"attribution_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyBoard = [aDecoder decodeIntForKey:@"board_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyColor = [aDecoder decodeIntForKey:@"color_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyLink = [aDecoder decodeIntForKey:@"link_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyIdentifier = [aDecoder decodeIntForKey:@"id_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyImage = [aDecoder decodeIntForKey:@"image_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyCreatedAt = [aDecoder decodeIntForKey:@"created_at_dirty_property"] & 0x1;
    _pinDirtyProperties.PinDirtyPropertyUrl = [aDecoder decodeIntForKey:@"url_dirty_property"] & 0x1;
    if ([self class] == [Pin class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.note forKey:@"note"];
    [aCoder encodeObject:self.media forKey:@"media"];
    [aCoder encodeObject:self.counts forKey:@"counts"];
    [aCoder encodeObject:self.descriptionText forKey:@"description"];
    [aCoder encodeObject:self.creator forKey:@"creator"];
    [aCoder encodeObject:self.attribution forKey:@"attribution"];
    [aCoder encodeObject:self.board forKey:@"board"];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.link forKey:@"link"];
    [aCoder encodeObject:self.identifier forKey:@"id"];
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.createdAt forKey:@"created_at"];
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyNote forKey:@"note_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyMedia forKey:@"media_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyCounts forKey:@"counts_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyDescriptionText forKey:@"description_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyCreator forKey:@"creator_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyAttribution forKey:@"attribution_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyBoard forKey:@"board_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyColor forKey:@"color_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyLink forKey:@"link_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyIdentifier forKey:@"id_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyImage forKey:@"image_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyCreatedAt forKey:@"created_at_dirty_property"];
    [aCoder encodeInt:_pinDirtyProperties.PinDirtyPropertyUrl forKey:@"url_dirty_property"];
}
@end

@implementation PinBuilder
- (instancetype)initWithModel:(Pin *)modelObject
{
    NSParameterAssert(modelObject);
    if (!(self = [super init])) {
        return self;
    }
    struct PinDirtyProperties pinDirtyProperties = modelObject.pinDirtyProperties;
    if (pinDirtyProperties.PinDirtyPropertyNote) {
        _note = modelObject.note;
    }
    if (pinDirtyProperties.PinDirtyPropertyMedia) {
        _media = modelObject.media;
    }
    if (pinDirtyProperties.PinDirtyPropertyCounts) {
        _counts = modelObject.counts;
    }
    if (pinDirtyProperties.PinDirtyPropertyDescriptionText) {
        _descriptionText = modelObject.descriptionText;
    }
    if (pinDirtyProperties.PinDirtyPropertyCreator) {
        _creator = modelObject.creator;
    }
    if (pinDirtyProperties.PinDirtyPropertyAttribution) {
        _attribution = modelObject.attribution;
    }
    if (pinDirtyProperties.PinDirtyPropertyBoard) {
        _board = modelObject.board;
    }
    if (pinDirtyProperties.PinDirtyPropertyColor) {
        _color = modelObject.color;
    }
    if (pinDirtyProperties.PinDirtyPropertyLink) {
        _link = modelObject.link;
    }
    if (pinDirtyProperties.PinDirtyPropertyIdentifier) {
        _identifier = modelObject.identifier;
    }
    if (pinDirtyProperties.PinDirtyPropertyImage) {
        _image = modelObject.image;
    }
    if (pinDirtyProperties.PinDirtyPropertyCreatedAt) {
        _createdAt = modelObject.createdAt;
    }
    if (pinDirtyProperties.PinDirtyPropertyUrl) {
        _url = modelObject.url;
    }
    _pinDirtyProperties = pinDirtyProperties;
    return self;
}
- (Pin *)build
{
    return [[Pin alloc] initWithBuilder:self];
}
- (void)mergeWithModel:(Pin *)modelObject
{
    NSParameterAssert(modelObject);
    PinBuilder *builder = self;
    if (modelObject.pinDirtyProperties.PinDirtyPropertyNote) {
        builder.note = modelObject.note;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyMedia) {
        builder.media = modelObject.media;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyCounts) {
        builder.counts = modelObject.counts;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyDescriptionText) {
        builder.descriptionText = modelObject.descriptionText;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyCreator) {
        builder.creator = modelObject.creator;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyAttribution) {
        builder.attribution = modelObject.attribution;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyBoard) {
        id value = modelObject.board;
        if (value != nil) {
            if (builder.board) {
                builder.board = [builder.board mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];
            }
             else {
                builder.board = value;
            }
        }
         else {
            builder.board = nil;
        }
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyColor) {
        builder.color = modelObject.color;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyLink) {
        builder.link = modelObject.link;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyIdentifier) {
        builder.identifier = modelObject.identifier;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyImage) {
        id value = modelObject.image;
        if (value != nil) {
            if (builder.image) {
                builder.image = [builder.image mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];
            }
             else {
                builder.image = value;
            }
        }
         else {
            builder.image = nil;
        }
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyCreatedAt) {
        builder.createdAt = modelObject.createdAt;
    }
    if (modelObject.pinDirtyProperties.PinDirtyPropertyUrl) {
        builder.url = modelObject.url;
    }
}
- (void)setNote:(NSString *)note
{
    _note = note;
    _pinDirtyProperties.PinDirtyPropertyNote = 1;
}
- (void)setMedia:(NSDictionary<NSString *, NSString *> *)media
{
    _media = media;
    _pinDirtyProperties.PinDirtyPropertyMedia = 1;
}
- (void)setCounts:(NSDictionary<NSString *, NSNumber /* Integer */ *> *)counts
{
    _counts = counts;
    _pinDirtyProperties.PinDirtyPropertyCounts = 1;
}
- (void)setDescriptionText:(NSString *)descriptionText
{
    _descriptionText = descriptionText;
    _pinDirtyProperties.PinDirtyPropertyDescriptionText = 1;
}
- (void)setCreator:(NSDictionary<NSString *, User *> *)creator
{
    _creator = creator;
    _pinDirtyProperties.PinDirtyPropertyCreator = 1;
}
- (void)setAttribution:(NSDictionary<NSString *, NSString *> *)attribution
{
    _attribution = attribution;
    _pinDirtyProperties.PinDirtyPropertyAttribution = 1;
}
- (void)setBoard:(Board *)board
{
    _board = board;
    _pinDirtyProperties.PinDirtyPropertyBoard = 1;
}
- (void)setColor:(NSString *)color
{
    _color = color;
    _pinDirtyProperties.PinDirtyPropertyColor = 1;
}
- (void)setLink:(NSURL *)link
{
    _link = link;
    _pinDirtyProperties.PinDirtyPropertyLink = 1;
}
- (void)setIdentifier:(NSString *)identifier
{
    _identifier = identifier;
    _pinDirtyProperties.PinDirtyPropertyIdentifier = 1;
}
- (void)setImage:(Image *)image
{
    _image = image;
    _pinDirtyProperties.PinDirtyPropertyImage = 1;
}
- (void)setCreatedAt:(NSDate *)createdAt
{
    _createdAt = createdAt;
    _pinDirtyProperties.PinDirtyPropertyCreatedAt = 1;
}
- (void)setUrl:(NSURL *)url
{
    _url = url;
    _pinDirtyProperties.PinDirtyPropertyUrl = 1;
}
@end
