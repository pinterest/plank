//
//  User.h
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

#import <Foundation/Foundation.h>
#import "PlankModelRuntime.h"
@class Image;
@class UserBuilder;

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject<NSCopying, NSSecureCoding>
@property (nullable, nonatomic, copy, readonly) NSString * lastName;
@property (nullable, nonatomic, copy, readonly) NSString * identifier;
@property (nullable, nonatomic, copy, readonly) NSString * firstName;
@property (nullable, nonatomic, strong, readonly) Image * image;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, NSNumber /* Integer */ *> * counts;
@property (nullable, nonatomic, strong, readonly) NSDate * createdAt;
@property (nullable, nonatomic, copy, readonly) NSString * username;
@property (nullable, nonatomic, copy, readonly) NSString * bio;
+ (NSString *)className;
+ (NSString *)polymorphicTypeIdentifier;
+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithModelDictionary:(NS_VALID_UNTIL_END_OF_SCOPE NSDictionary *)modelDictionary;
- (instancetype)initWithBuilder:(UserBuilder *)builder;
- (instancetype)initWithBuilder:(UserBuilder *)builder initType:(PlankModelInitType)initType;
- (instancetype)copyWithBlock:(PLANK_NOESCAPE void (^)(UserBuilder *builder))block;
- (BOOL)isEqualToUser:(User *)anObject;
- (instancetype)mergeWithModel:(User *)modelObject;
- (instancetype)mergeWithModel:(User *)modelObject initType:(PlankModelInitType)initType;
- (NSDictionary *)dictionaryObjectRepresentation;
@end

@interface UserBuilder : NSObject
@property (nullable, nonatomic, copy, readwrite) NSString * lastName;
@property (nullable, nonatomic, copy, readwrite) NSString * identifier;
@property (nullable, nonatomic, copy, readwrite) NSString * firstName;
@property (nullable, nonatomic, strong, readwrite) Image * image;
@property (nullable, nonatomic, strong, readwrite) NSDictionary<NSString *, NSNumber /* Integer */ *> * counts;
@property (nullable, nonatomic, strong, readwrite) NSDate * createdAt;
@property (nullable, nonatomic, copy, readwrite) NSString * username;
@property (nullable, nonatomic, copy, readwrite) NSString * bio;
- (instancetype)initWithModel:(User *)modelObject;
- (User *)build;
- (void)mergeWithModel:(User *)modelObject;
@end

NS_ASSUME_NONNULL_END
