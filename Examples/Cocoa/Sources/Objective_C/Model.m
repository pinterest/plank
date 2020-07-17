//
// Model.m
// Autogenerated by Plank (https://pinterest.github.io/plank/)
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

#import "Model.h"

struct ModelDirtyProperties {
    unsigned int ModelDirtyPropertyIdentifier:1;
};

@interface Model ()
@property (nonatomic, assign, readwrite) struct ModelDirtyProperties modelDirtyProperties;
@end

@interface ModelBuilder ()
@property (nonatomic, assign, readwrite) struct ModelDirtyProperties modelDirtyProperties;
@end

@implementation Model
+ (NSString *)className
{
    return @"Model";
}
+ (NSString *)polymorphicTypeIdentifier
{
    return @"model";
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
    if (!modelDictionary) {
        return self;
    }
    if (!(self = [super init])) {
        return self;
    }
    {
        __unsafe_unretained id value = modelDictionary[@"id"];
        if (value != nil) {
            self->_modelDirtyProperties.ModelDirtyPropertyIdentifier = 1;
            if (value != (id)kCFNull) {
                if (!error || [value isKindOfClass:[NSString class]]) {
                    self->_identifier = [value copy];
                } else {
                    self->_modelDirtyProperties.ModelDirtyPropertyIdentifier = 0;
                    *error = PlankTypeError(@"id", [NSString class], [value class]);
                }
            }
        }
    }
    if ([self class] == [Model class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (instancetype)initWithBuilder:(ModelBuilder *)builder
{
    NSParameterAssert(builder);
    return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];
}
- (instancetype)initWithBuilder:(ModelBuilder *)builder initType:(PlankModelInitType)initType
{
    NSParameterAssert(builder);
    if (!(self = [super init])) {
        return self;
    }
    _identifier = builder.identifier;
    _modelDirtyProperties = builder.modelDirtyProperties;
    if ([self class] == [Model class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(initType) }];
    }
    return self;
}
#ifdef DEBUG
- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:1];
    [descriptionFields addObject:parentDebugDescription];
    struct ModelDirtyProperties props = _modelDirtyProperties;
    if (props.ModelDirtyPropertyIdentifier) {
        [descriptionFields addObject:[NSString stringWithFormat:@"_identifier = %@", _identifier]];
    }
    return [NSString stringWithFormat:@"Model = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
#endif
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(ModelBuilder *builder))block
{
    NSParameterAssert(block);
    ModelBuilder *builder = [[ModelBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if ([anObject isKindOfClass:[Model class]] == NO) {
        return NO;
    }
    return [self isEqualToModel:anObject];
}
- (BOOL)isEqualToModel:(Model *)anObject
{
    return (
        (anObject != nil) &&
        (_identifier == anObject.identifier || [_identifier isEqualToString:anObject.identifier])
    );
}
- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        17,
        [_identifier hash]
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
- (instancetype)mergeWithModel:(Model *)modelObject
{
    return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];
}
- (instancetype)mergeWithModel:(Model *)modelObject initType:(PlankModelInitType)initType
{
    NSParameterAssert(modelObject);
    ModelBuilder *builder = [[ModelBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[Model alloc] initWithBuilder:builder initType:initType];
}
- (NSDictionary *)dictionaryObjectRepresentation
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (_modelDirtyProperties.ModelDirtyPropertyIdentifier) {
        if (_identifier != nil) {
            [dict setObject:_identifier forKey:@"id"];
        } else {
            [dict setObject:[NSNull null] forKey:@"id"];
        }
    }
    return dict;
}
- (BOOL)isIdentifierSet
{
    return _modelDirtyProperties.ModelDirtyPropertyIdentifier == 1;
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
    _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"id"];
    _modelDirtyProperties.ModelDirtyPropertyIdentifier = [aDecoder decodeIntForKey:@"id_dirty_property"] & 0x1;
    if ([self class] == [Model class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.identifier forKey:@"id"];
    [aCoder encodeInt:_modelDirtyProperties.ModelDirtyPropertyIdentifier forKey:@"id_dirty_property"];
}
@end

@implementation ModelBuilder
- (instancetype)initWithModel:(Model *)modelObject
{
    NSParameterAssert(modelObject);
    if (!(self = [super init])) {
        return self;
    }
    struct ModelDirtyProperties modelDirtyProperties = modelObject.modelDirtyProperties;
    if (modelDirtyProperties.ModelDirtyPropertyIdentifier) {
        _identifier = modelObject.identifier;
    }
    _modelDirtyProperties = modelDirtyProperties;
    return self;
}
- (Model *)build
{
    return [[Model alloc] initWithBuilder:self];
}
- (void)mergeWithModel:(Model *)modelObject
{
    NSParameterAssert(modelObject);
    ModelBuilder *builder = self;
    if (modelObject.modelDirtyProperties.ModelDirtyPropertyIdentifier) {
        builder.identifier = modelObject.identifier;
    }
}
- (void)setIdentifier:(NSString *)identifier
{
    _identifier = [identifier copy];
    _modelDirtyProperties.ModelDirtyPropertyIdentifier = 1;
}
@end
