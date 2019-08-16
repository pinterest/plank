//
// VariableSubtitution.m
// Autogenerated by Plank (https://pinterest.github.io/plank/)
//
// DO NOT EDIT - EDITS WILL BE OVERWRITTEN
// @generated
//

#import "VariableSubtitution.h"

struct VariableSubtitutionDirtyProperties {
    unsigned int VariableSubtitutionDirtyPropertyAllocProp:1;
    unsigned int VariableSubtitutionDirtyPropertyCopyProp:1;
    unsigned int VariableSubtitutionDirtyPropertyMutableCopyProp:1;
    unsigned int VariableSubtitutionDirtyPropertyNewProp:1;
};

@interface VariableSubtitution ()
@property (nonatomic, assign, readwrite) struct VariableSubtitutionDirtyProperties variableSubtitutionDirtyProperties;
@end

@interface VariableSubtitutionBuilder ()
@property (nonatomic, assign, readwrite) struct VariableSubtitutionDirtyProperties variableSubtitutionDirtyProperties;
@end

@implementation VariableSubtitution
+ (NSString *)className
{
    return @"VariableSubtitution";
}
+ (NSString *)polymorphicTypeIdentifier
{
    return @"variable_subtitution";
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
            __unsafe_unretained id value = modelDictionary[@"alloc_prop"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_allocProp = [value integerValue];
                }
                self->_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"copy_prop"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_copyProp = [value integerValue];
                }
                self->_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"mutable_copy_prop"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_mutableCopyProp = [value integerValue];
                }
                self->_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp = 1;
            }
        }
        {
            __unsafe_unretained id value = modelDictionary[@"new_prop"]; // Collection will retain.
            if (value != nil) {
                if (value != (id)kCFNull) {
                    self->_newProp = [value integerValue];
                }
                self->_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp = 1;
            }
        }
    if ([self class] == [VariableSubtitution class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (instancetype)initWithBuilder:(VariableSubtitutionBuilder *)builder
{
    NSParameterAssert(builder);
    return [self initWithBuilder:builder initType:PlankModelInitTypeDefault];
}
- (instancetype)initWithBuilder:(VariableSubtitutionBuilder *)builder initType:(PlankModelInitType)initType
{
    NSParameterAssert(builder);
    if (!(self = [super init])) {
        return self;
    }
    _allocProp = builder.allocProp;
    _copyProp = builder.copyProp;
    _mutableCopyProp = builder.mutableCopyProp;
    _newProp = builder.newProp;
    _variableSubtitutionDirtyProperties = builder.variableSubtitutionDirtyProperties;
    if ([self class] == [VariableSubtitution class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(initType) }];
    }
    return self;
}
- (NSString *)debugDescription
{
    NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:@"\n"];
    NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:4];
    [descriptionFields addObject:parentDebugDescription];
    struct VariableSubtitutionDirtyProperties props = _variableSubtitutionDirtyProperties;
    if (props.VariableSubtitutionDirtyPropertyAllocProp) {
        [descriptionFields addObject:[@"_allocProp = " stringByAppendingFormat:@"%@", @(_allocProp)]];
    }
    if (props.VariableSubtitutionDirtyPropertyCopyProp) {
        [descriptionFields addObject:[@"_copyProp = " stringByAppendingFormat:@"%@", @(_copyProp)]];
    }
    if (props.VariableSubtitutionDirtyPropertyMutableCopyProp) {
        [descriptionFields addObject:[@"_mutableCopyProp = " stringByAppendingFormat:@"%@", @(_mutableCopyProp)]];
    }
    if (props.VariableSubtitutionDirtyPropertyNewProp) {
        [descriptionFields addObject:[@"_newProp = " stringByAppendingFormat:@"%@", @(_newProp)]];
    }
    return [NSString stringWithFormat:@"VariableSubtitution = {\n%@\n}", debugDescriptionForFields(descriptionFields)];
}
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(VariableSubtitutionBuilder *builder))block
{
    NSParameterAssert(block);
    VariableSubtitutionBuilder *builder = [[VariableSubtitutionBuilder alloc] initWithModel:self];
    block(builder);
    return [builder build];
}
- (BOOL)isEqual:(id)anObject
{
    if (self == anObject) {
        return YES;
    }
    if ([anObject isKindOfClass:[VariableSubtitution class]] == NO) {
        return NO;
    }
    return [self isEqualToVariableSubtitution:anObject];
}
- (BOOL)isEqualToVariableSubtitution:(VariableSubtitution *)anObject
{
    return (
        (anObject != nil) &&
        (_newProp == anObject.newProp) &&
        (_mutableCopyProp == anObject.mutableCopyProp) &&
        (_copyProp == anObject.copyProp) &&
        (_allocProp == anObject.allocProp)
    );
}
- (NSUInteger)hash
{
    NSUInteger subhashes[] = {
        17,
        (NSUInteger)_allocProp,
        (NSUInteger)_copyProp,
        (NSUInteger)_mutableCopyProp,
        (NSUInteger)_newProp
    };
    return PINIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
- (instancetype)mergeWithModel:(VariableSubtitution *)modelObject
{
    return [self mergeWithModel:modelObject initType:PlankModelInitTypeFromMerge];
}
- (instancetype)mergeWithModel:(VariableSubtitution *)modelObject initType:(PlankModelInitType)initType
{
    NSParameterAssert(modelObject);
    VariableSubtitutionBuilder *builder = [[VariableSubtitutionBuilder alloc] initWithModel:self];
    [builder mergeWithModel:modelObject];
    return [[VariableSubtitution alloc] initWithBuilder:builder initType:initType];
}
- (NSDictionary *)dictionaryObjectRepresentation
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    if (_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp) {
        [dict setObject:@(_allocProp) forKey: @"alloc_prop"];
    }
    if (_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp) {
        [dict setObject:@(_copyProp) forKey: @"copy_prop"];
    }
    if (_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp) {
        [dict setObject:@(_mutableCopyProp) forKey: @"mutable_copy_prop"];
    }
    if (_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp) {
        [dict setObject:@(_newProp) forKey: @"new_prop"];
    }
    return dict;
}
- (BOOL)isAllocPropSet
{
    return _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp == 1;
}
- (BOOL)isCopyPropSet
{
    return _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp == 1;
}
- (BOOL)isMutableCopyPropSet
{
    return _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp == 1;
}
- (BOOL)isNewPropSet
{
    return _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp == 1;
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
    _allocProp = [aDecoder decodeIntegerForKey:@"alloc_prop"];
    _copyProp = [aDecoder decodeIntegerForKey:@"copy_prop"];
    _mutableCopyProp = [aDecoder decodeIntegerForKey:@"mutable_copy_prop"];
    _newProp = [aDecoder decodeIntegerForKey:@"new_prop"];
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp = [aDecoder decodeIntForKey:@"alloc_prop_dirty_property"] & 0x1;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp = [aDecoder decodeIntForKey:@"copy_prop_dirty_property"] & 0x1;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp = [aDecoder decodeIntForKey:@"mutable_copy_prop_dirty_property"] & 0x1;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp = [aDecoder decodeIntForKey:@"new_prop_dirty_property"] & 0x1;
    if ([self class] == [VariableSubtitution class]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlankDidInitializeNotification object:self userInfo:@{ kPlankInitTypeKey : @(PlankModelInitTypeDefault) }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.allocProp forKey:@"alloc_prop"];
    [aCoder encodeInteger:self.copyProp forKey:@"copy_prop"];
    [aCoder encodeInteger:self.mutableCopyProp forKey:@"mutable_copy_prop"];
    [aCoder encodeInteger:self.newProp forKey:@"new_prop"];
    [aCoder encodeInt:_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp forKey:@"alloc_prop_dirty_property"];
    [aCoder encodeInt:_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp forKey:@"copy_prop_dirty_property"];
    [aCoder encodeInt:_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp forKey:@"mutable_copy_prop_dirty_property"];
    [aCoder encodeInt:_variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp forKey:@"new_prop_dirty_property"];
}
@end

@implementation VariableSubtitutionBuilder
- (instancetype)initWithModel:(VariableSubtitution *)modelObject
{
    NSParameterAssert(modelObject);
    if (!(self = [super init])) {
        return self;
    }
    struct VariableSubtitutionDirtyProperties variableSubtitutionDirtyProperties = modelObject.variableSubtitutionDirtyProperties;
    if (variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp) {
        _allocProp = modelObject.allocProp;
    }
    if (variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp) {
        _copyProp = modelObject.copyProp;
    }
    if (variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp) {
        _mutableCopyProp = modelObject.mutableCopyProp;
    }
    if (variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp) {
        _newProp = modelObject.newProp;
    }
    _variableSubtitutionDirtyProperties = variableSubtitutionDirtyProperties;
    return self;
}
- (VariableSubtitution *)build
{
    return [[VariableSubtitution alloc] initWithBuilder:self];
}
- (void)mergeWithModel:(VariableSubtitution *)modelObject
{
    NSParameterAssert(modelObject);
    VariableSubtitutionBuilder *builder = self;
    if (modelObject.variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp) {
        builder.allocProp = modelObject.allocProp;
    }
    if (modelObject.variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp) {
        builder.copyProp = modelObject.copyProp;
    }
    if (modelObject.variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp) {
        builder.mutableCopyProp = modelObject.mutableCopyProp;
    }
    if (modelObject.variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp) {
        builder.newProp = modelObject.newProp;
    }
}
- (void)setAllocProp:(NSInteger)allocProp
{
    _allocProp = allocProp;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyAllocProp = 1;
}
- (void)setCopyProp:(NSInteger)copyProp
{
    _copyProp = copyProp;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyCopyProp = 1;
}
- (void)setMutableCopyProp:(NSInteger)mutableCopyProp
{
    _mutableCopyProp = mutableCopyProp;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyMutableCopyProp = 1;
}
- (void)setNewProp:(NSInteger)newProp
{
    _newProp = newProp;
    _variableSubtitutionDirtyProperties.VariableSubtitutionDirtyPropertyNewProp = 1;
}
@end
