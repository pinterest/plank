//
//  Board.h
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

#import <Foundation/Foundation.h>
#import "PlankModelRuntime.h"
@class BoardBuilder;
@class Image;

NS_ASSUME_NONNULL_BEGIN

@interface Board : NSObject<NSCopying, NSSecureCoding>
@property (nullable, nonatomic, copy, readonly) NSString * name;
@property (nullable, nonatomic, copy, readonly) NSString * identifier;
@property (nullable, nonatomic, strong, readonly) Image * image;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, NSNumber /* Integer */ *> * counts;
@property (nullable, nonatomic, strong, readonly) NSDate * createdAt;
@property (nullable, nonatomic, copy, readonly) NSString * descriptionText;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> * creator;
@property (nullable, nonatomic, strong, readonly) NSURL * url;
+ (NSString *)className;
+ (NSString *)polymorphicTypeIdentifier;
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithModelDictionary:(NS_VALID_UNTIL_END_OF_SCOPE NSDictionary *)modelDictionary;
- (instancetype)initWithBuilder:(BoardBuilder *)builder;
- (instancetype)initWithBuilder:(BoardBuilder *)builder initType:(PlankModelInitType)initType;
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(BoardBuilder *builder))block;
- (BOOL)isEqualToBoard:(Board *)anObject;
- (instancetype)mergeWithModel:(Board *)modelObject;
- (instancetype)mergeWithModel:(Board *)modelObject initType:(PlankModelInitType)initType;
- (NSDictionary *)dictionaryRepresentation;
@end

@interface BoardBuilder : NSObject
@property (nullable, nonatomic, copy, readwrite) NSString * name;
@property (nullable, nonatomic, copy, readwrite) NSString * identifier;
@property (nullable, nonatomic, strong, readwrite) Image * image;
@property (nullable, nonatomic, strong, readwrite) NSDictionary<NSString *, NSNumber /* Integer */ *> * counts;
@property (nullable, nonatomic, strong, readwrite) NSDate * createdAt;
@property (nullable, nonatomic, copy, readwrite) NSString * descriptionText;
@property (nullable, nonatomic, strong, readwrite) NSDictionary<NSString *, NSString *> * creator;
@property (nullable, nonatomic, strong, readwrite) NSURL * url;
- (instancetype)initWithModel:(Board *)modelObject;
- (Board *)build;
- (void)mergeWithModel:(Board *)modelObject;
@end

NS_ASSUME_NONNULL_END
