//
//  ObjCImplementationFileGeneratorTests.swift
//  pinmodel
//
//  Created by Andrew Chun on 6/10/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import XCTest

import Foundation

@testable import pinmodel

class ObjCImplementationFileGeneratorTests: PINModelTests {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDirtyPropertiesIVarNameForBaseClass() {
        let dirtyPropertiesIVarName = baseImpl.dirtyPropertiesIVarName
        let expectedIVarName = "baseDirtyProperties"

        XCTAssertEqual(dirtyPropertiesIVarName, expectedIVarName)
    }

    func testDirtyPropertiesIVarNameForChildClass() {
        let dirtyPropertiesIVarName = childImpl.dirtyPropertiesIVarName
        let expectedIVarName = "dirtyProperties"

        XCTAssertEqual(dirtyPropertiesIVarName, expectedIVarName)
    }

    func testRenderPrivateInterfaceForBaseClass() {
        let importsString = baseImpl.renderPrivateInterface()
        let expectedImports = [
            "@interface PIModel ()",
            "@property (nonatomic, assign) struct PIModelDirtyProperties baseDirtyProperties;",
            "@end\n",
            "@interface PIModelBuilder ()",
            "@property (nonatomic, assign) struct PIModelDirtyProperties baseDirtyProperties;",
            "@end"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(importsString, expectedCode: expectedImports)
    }

    func testRenderPrivateInterfaceForChildClass() {
        let importsString = childImpl.renderPrivateInterface()
        let expectedImports = [
            "@interface PINotification ()",
            "@property (nonatomic, assign) struct PIModelDirtyProperties baseDirtyProperties;",
            "@property (nonatomic, assign) struct PINotificationDirtyProperties dirtyProperties;",
            "@end",
            "",
            "@interface PINotificationBuilder ()",
            "@property (nonatomic, assign) struct PIModelDirtyProperties baseDirtyProperties;",
            "@property (nonatomic, assign) struct PINotificationDirtyProperties dirtyProperties;",
            "@end"
            ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(importsString, expectedCode: expectedImports)
    }

    func testRenderDirtyPropertiesForBaseClass() {
        let dirtyProperties = baseImpl.renderDirtyPropertyOptions()
        let expectedDirtyProperties = [
            "struct PIModelDirtyProperties {",
            "    unsigned int PIModelDirtyPropertyAdditionalLocalNonApiProperties:1;",
            "    unsigned int PIModelDirtyPropertyIdentifier:1;",
            "};"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(dirtyProperties, expectedCode: expectedDirtyProperties)
    }

    func testRenderDirtyPropertiesForChildClass() {
        let dirtyProperties = childImpl.renderDirtyPropertyOptions()
        let expectedDirtyProperties = [
            "struct PINotificationDirtyProperties {",
            "    unsigned int PINotificationDirtyPropertySections:1;",
            "    unsigned int PINotificationDirtyPropertyStyle:1;",
            "};"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(dirtyProperties, expectedCode: expectedDirtyProperties)
    }

    func testRenderInitWithDictionaryForBaseClass() {
        let initString = baseImpl.renderInitWithDictionary()
        let expectedInit = [
            "- (instancetype) __attribute__((annotate(\"oclint:suppress[high npath complexity]\")))",
            "    initWithDictionary:(NSDictionary *)modelDictionary",
            "{",
            "    NSParameterAssert(modelDictionary);",
            "    if (!(self = [super init])) { return self; }",
            "",
            "    [modelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
            "",
            "        if ([key isEqualToString:@\"additional_local_non_API_properties\"]) {",
            "            _additionalLocalNonApiProperties = valueOrNil(modelDictionary, @\"additional_local_non_API_properties\");",
            "            _baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties = 1;",
            "            return;",
            "        }",
            "",
            "        if ([key isEqualToString:@\"id\"]) {",
            "            _identifier = valueOrNil(modelDictionary, @\"id\");",
            "            _baseDirtyProperties.PIModelDirtyPropertyIdentifier = 1;",
            "            return;",
            "        }",
            "    }];",
            "",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initString, expectedCode: expectedInit)
    }

    func testRenderInitWithDictionaryForChildClass() {
        let initString = childImpl.renderInitWithDictionary()
        let expectedInit = [
            "- (instancetype) __attribute__((annotate(\"oclint:suppress[high npath complexity]\")))",
            "    initWithDictionary:(NSDictionary *)modelDictionary",
            "{",
            "    NSParameterAssert(modelDictionary);",
            "    if (!(self = [super initWithDictionary:modelDictionary])) { return self; }",
            "",
            "    [modelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {",
            "",
            "        if ([key isEqualToString:@\"sections\"]) {",
            "            id value = valueOrNil(modelDictionary, @\"sections\");",
            "            if (value != nil) {",
            "                _sections = [[PINotificationSections alloc] initWithDictionary:value];",
            "            }",
            "            _dirtyProperties.PINotificationDirtyPropertySections = 1;",
            "            return;",
            "        }",
            "",
            "        if ([key isEqualToString:@\"style\"]) {",
            "            _style = valueOrNil(modelDictionary, @\"style\");",
            "            _dirtyProperties.PINotificationDirtyPropertyStyle = 1;",
            "            return;",
            "        }",
            "    }];",
            "",
            "    [self PIModelDidInitialize:PIModelInitTypeDefault];",
            "",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initString, expectedCode: expectedInit)
    }

    func testRenderInitWithBuilderForBaseClass() {
        let initBuilderString = baseImpl.renderInitWithBuilder()
        let expectedInitBuilder = [
            "- (instancetype)initWithBuilder:(PIModelBuilder *)builder",
            "{",
            "    NSParameterAssert(builder);",
            "    if (!(self = [super init])) { return self; }",
            "    _additionalLocalNonApiProperties = builder.additionalLocalNonApiProperties;",
            "    _identifier = builder.identifier;",
            "    _baseDirtyProperties = builder.baseDirtyProperties;",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initBuilderString, expectedCode: expectedInitBuilder)
    }

    func testRenderInitWithBuilderForChildClass() {
        let initBuilderString = childImpl.renderInitWithBuilder()
        let expectedInitBuilder = [
            "- (instancetype)initWithBuilder:(PINotificationBuilder *)builder",
            "{",
            "    return [self initWithBuilder:builder initType:PIModelInitTypeDefault];",
            "}",
            "",
            "- (instancetype)initWithBuilder:(PINotificationBuilder *)builder initType:(PIModelInitType)initType",
            "{",
            "    NSParameterAssert(builder);",
            "    if (!(self = [super initWithBuilder:builder])) { return self; }",
            "    _sections = builder.sections;",
            "    _style = builder.style;",
            "    _dirtyProperties = builder.dirtyProperties;",
            "    [self PIModelDidInitialize:initType];",
            "    return self;",
            "}",
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initBuilderString, expectedCode: expectedInitBuilder)
    }

    func testRenderBuilderInitWithModelObjectForBaseClass() {
        let initWithModelString = baseImpl.renderBuilderInitWithModelObject()
        let expectedInitModel = [
            "- (instancetype)initWithModel:(PIModel *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            "    if (!(self = [super init])) { return self; }",
            "",
            "    struct PIModelDirtyProperties baseDirtyProperties = modelObject.baseDirtyProperties;",
            "",
            "    if (baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties) {",
            "        _additionalLocalNonApiProperties = modelObject.additionalLocalNonApiProperties;",
            "    }",
            "    if (baseDirtyProperties.PIModelDirtyPropertyIdentifier) {",
            "        _identifier = modelObject.identifier;",
            "    }",
            "",
            "    _baseDirtyProperties = baseDirtyProperties;",
            "",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initWithModelString, expectedCode: expectedInitModel)
    }

    func testRenderBuilderInitWithModelObjectForChildClass() {
        let initWIthModelString = childImpl.renderBuilderInitWithModelObject()
        let expectedInitModel = [
            "- (instancetype)initWithModel:(PINotification *)modelObject",
            "{",
            "    NSParameterAssert(modelObject);",
            "    if (!(self = [super initWithModel:modelObject])) { return self; }",
            "",
            "    struct PINotificationDirtyProperties dirtyProperties = modelObject.dirtyProperties;",
            "",
            "    if (dirtyProperties.PINotificationDirtyPropertySections) {",
            "        _sections = modelObject.sections;",
            "    }",
            "    if (dirtyProperties.PINotificationDirtyPropertyStyle) {",
            "        _style = modelObject.style;",
            "    }",
            "",
            "    _dirtyProperties = dirtyProperties;",
            "",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initWIthModelString, expectedCode: expectedInitModel)
    }

    func testRenderInitWithCoderForBaseClass() {
        let initWithCoderString = baseImpl.renderInitWithCoder()
        let expectedInitCoder = [
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            "    if (!(self = [super init])) { return self; }",
            "",
            "    _additionalLocalNonApiProperties = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary class], [NSString class]]] forKey:@\"additional_local_non_API_properties\"];",
            "",
            "    _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@\"id\"];",
            "",
            "",
            "    _baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties = [aDecoder decodeIntForKey:@\"additional_local_non_API_properties_dirty_property\"];",
            "",
            "    _baseDirtyProperties.PIModelDirtyPropertyIdentifier = [aDecoder decodeIntForKey:@\"id_dirty_property\"];",
            "",
            "    return self;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initWithCoderString, expectedCode: expectedInitCoder)
    }

    func testRenderInitWithCoderForChildClass() {
        let initWithCoderString = childImpl.renderInitWithCoder()
        let expectedInitCoder = [
            "- (instancetype)initWithCoder:(NSCoder *)aDecoder",
            "{",
            "    if (!(self = [super initWithCoder:aDecoder])) { return self; }",
            "",
            "    _sections = [aDecoder decodeObjectOfClass:[PINotificationSections class] forKey:@\"sections\"];",
            "",
            "    _style = [aDecoder decodeObjectOfClass:[NSString class] forKey:@\"style\"];",
            "",
            "",
            "    _dirtyProperties.PINotificationDirtyPropertySections = [aDecoder decodeIntForKey:@\"sections_dirty_property\"];",
            "",
            "    _dirtyProperties.PINotificationDirtyPropertyStyle = [aDecoder decodeIntForKey:@\"style_dirty_property\"];",
            "",
            "    [self PIModelDidInitialize:PIModelInitTypeDefault];",
            "",
            "    return self;",
            "}",
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(initWithCoderString, expectedCode: expectedInitCoder)
    }

    func testRenderEncodeWithCoderForBaseClass() {
        let encodeString = baseImpl.renderEncodeWithCoder()
        let expectedEncodeString = [
            "- (void)encodeWithCoder:(NSCoder *)aCoder",
            "{",
            "    [aCoder encodeObject:self.additionalLocalNonApiProperties forKey:@\"additional_local_non_API_properties\"];",
            "",
            "    [aCoder encodeObject:self.identifier forKey:@\"id\"];",
            "",
            "    [aCoder encodeInt:_baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties forKey:@\"additional_local_non_API_properties_dirty_property\"];",
            "",
            "    [aCoder encodeInt:_baseDirtyProperties.PIModelDirtyPropertyIdentifier forKey:@\"id_dirty_property\"];",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(encodeString, expectedCode: expectedEncodeString)
    }

    func testRenderMergeWithModelForBaseClass() {
        let mergeWithModelString = baseImpl.renderMergeWithModel()
        let expectedMergeWithModel = [
            "- (instancetype)mergeWithModel:(PIModel *)modelObject {",
            "    return [self mergeWithModel:modelObject initType:PIModelInitTypeFromMerge];",
            "}",
            "",
            "- (instancetype)mergeWithModel:(PIModel *)modelObject initType:(PIModelInitType)initType",
            "{",
            "    NSParameterAssert(modelObject);",
            "    PIModelBuilder *builder = [[PIModelBuilder alloc] initWithModel:self];",
            "",
            "",
            "    if (modelObject.baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties) {",
            "        if (builder.additionalLocalNonApiProperties) {",
            "            NSMutableDictionary *mutableProperties = [[NSMutableDictionary alloc] initWithDictionary:builder.additionalLocalNonApiProperties];",
            "            [mutableProperties addEntriesFromDictionary:modelObject.additionalLocalNonApiProperties];",
            "            builder.additionalLocalNonApiProperties = mutableProperties;",
            "        } else {",
            "            builder.additionalLocalNonApiProperties = modelObject.additionalLocalNonApiProperties;",
            "        }",
            "    }",
            "",
            "    if (modelObject.baseDirtyProperties.PIModelDirtyPropertyIdentifier) {",
            "        builder.identifier = modelObject.identifier;",
            "    }",
            "",
            "    return [builder build];",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(mergeWithModelString, expectedCode: expectedMergeWithModel)
    }

    func testRenderMergeWithModelForChildClass() {
        let mergeWithModelString = childImpl.renderMergeWithModel()
        let expectedMergeWithModel = [
            "- (instancetype)mergeWithModel:(PINotification *)modelObject {",
            "    return [self mergeWithModel:modelObject initType:PIModelInitTypeFromMerge];",
            "}",
            "",
            "- (instancetype)mergeWithModel:(PINotification *)modelObject initType:(PIModelInitType)initType",
            "{",
            "    NSParameterAssert(modelObject);",
            "    PINotificationBuilder *builder = [[PINotificationBuilder alloc] initWithModel:self];",
            "",
            "    if (modelObject.baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties) {",
            "        if (builder.additionalLocalNonApiProperties) {",
            "            NSMutableDictionary *mutableProperties = [[NSMutableDictionary alloc] initWithDictionary:builder.additionalLocalNonApiProperties];",
            "            [mutableProperties addEntriesFromDictionary:modelObject.additionalLocalNonApiProperties];",
            "            builder.additionalLocalNonApiProperties = mutableProperties;",
            "        } else {",
            "            builder.additionalLocalNonApiProperties = modelObject.additionalLocalNonApiProperties;",
            "        }",
            "    }",
            "",
            "    if (modelObject.baseDirtyProperties.PIModelDirtyPropertyIdentifier) {",
            "        builder.identifier = modelObject.identifier;",
            "    }",
            "    if (modelObject.dirtyProperties.PINotificationDirtyPropertySections) {",
            "        id value = modelObject.sections;",
            "        if (value != nil) {",
            "            if (builder.sections != nil) {",
            "                builder.sections = [builder.sections mergeWithModel:value initType:PIModelInitTypeFromSubmerge];",
            "            } else {",
            "                builder.sections = value;",
            "            }",
            "        } else {",
            "            builder.sections = nil;",
            "        }",
            "    }",
            "",
            "    if (modelObject.dirtyProperties.PINotificationDirtyPropertyStyle) {",
            "        builder.style = modelObject.style;",
            "    }",
            "",
            "    return [[PINotification alloc] initWithBuilder:builder initType:initType];",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(mergeWithModelString, expectedCode: expectedMergeWithModel)
    }

    func testRenderBuilderSettingsForBaseClass() {
        let settersString = baseImpl.renderBuilderSetters()
        let expectedSetters = [
            "- (void)setAdditionalLocalNonApiProperties:(NSDictionary <NSString *, __kindof NSObject *> *)additionalLocalNonApiProperties",
            "{",
            "    _additionalLocalNonApiProperties = additionalLocalNonApiProperties;",
            "    _baseDirtyProperties.PIModelDirtyPropertyAdditionalLocalNonApiProperties = 1;",
            "}",
            "",
            "- (void)setIdentifier:(NSString *)identifier",
            "{",
            "    _identifier = identifier;",
            "    _baseDirtyProperties.PIModelDirtyPropertyIdentifier = 1;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(settersString, expectedCode: expectedSetters)
    }

    func testRenderBuilderSettingsForChildClass() {
        let settersString = childImpl.renderBuilderSetters()
        let expectedSetters = [
            "- (void)setSections:(PINotificationSections *)sections",
            "{",
            "    _sections = sections;",
            "    _dirtyProperties.PINotificationDirtyPropertySections = 1;",
            "}",
            "",
            "- (void)setStyle:(NSString *)style",
            "{",
            "    _style = style;",
            "    _dirtyProperties.PINotificationDirtyPropertyStyle = 1;",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(settersString, expectedCode: expectedSetters)
    }


    func testRenderCopyWithBlock() {
        let copyWithBlockImpl = baseImpl.renderCopyWithBlock()

        let expectedCopyWithBlockImpl = [
            "- (instancetype)copyWithBlock:(__attribute__((noescape)) void (^)(\(baseImpl.builderClassName) *builder))block",
            "{",
            "    NSParameterAssert(block);",
            "    \(baseImpl.builderClassName) *builder = [[\(baseImpl.builderClassName) alloc] initWithModel:self];",
            "    block(builder);",
            "    return [builder build];",
            "}"
        ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(copyWithBlockImpl, expectedCode: expectedCopyWithBlockImpl)
    }

    func testPolymorphicTypeIdentifierFallbackToName() {
        // When `algebraicDataTypeIdentifier` is not specified, the fallback is the name of the schema.
        let pinSchema = ObjectSchemaObjectProperty(
            name: "pin",
            objectType: JSONType.Object,
            propertyInfo: [
                "properties": [
                    "id": [ "type": "string"],
                ]
            ],
            sourceId: URL(fileURLWithPath: "")
        )

        let impl = ObjectiveCImplementationFileDescriptor(
            descriptor: pinSchema,
            generatorParameters: [GenerationParameterType.classPrefix: "PI"],
            parentDescriptor: nil,
            schemaLoader: self.schemaLoader
        )

        let expectedMethodLines = [
            "+ (NSString *)polymorphicTypeIdentifier",
            "{",
            "    return @\"pin\";",
            "}"
            ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(impl.renderPolymorphicTypeIdentifier(), expectedCode: expectedMethodLines)
    }


    func testPolymorphicTypeIdentifierWithADT() {
        // The value for the ADT identifier should take precedence over `name` when specified.
        let pinSchema = ObjectSchemaObjectProperty(
            name: "pin",
            objectType: JSONType.Object,
            propertyInfo: [
                "algebraicDataTypeIdentifier" : "some_other_pin",
                "properties": [
                    "id": [ "type": "string"],
                ]
            ],
            sourceId: URL(fileURLWithPath: "")
        )

        let impl = ObjectiveCImplementationFileDescriptor(
            descriptor: pinSchema,
            generatorParameters: [GenerationParameterType.classPrefix: "PI"],
            parentDescriptor: nil,
            schemaLoader: self.schemaLoader
        )

        let expectedMethodLines = [
            "+ (NSString *)polymorphicTypeIdentifier",
            "{",
            "    return @\"some_other_pin\";",
            "}"
            ].joined(separator: "\n")

        PINModelTests.tokenizeAndAssertFlexibleEquality(impl.renderPolymorphicTypeIdentifier(), expectedCode: expectedMethodLines)
    }


}
