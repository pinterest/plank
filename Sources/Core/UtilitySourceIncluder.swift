//
//  UtilitySourceIncluder.swift
//  plank
//
//  Created by Michael Zuccarino on 10/22/18.
//

import Foundation

public struct UtilitySourceIncluder {
    
    let languages: [Languages]
    let outputDirectory: URL
    let generationParameters: GenerationParameters
    
    public init(languages langs: [Languages],
                outputDirectory outputDir: URL,
                generationParameters genParams: GenerationParameters) {
        languages = langs
        outputDirectory = outputDir
        generationParameters = genParams
    }

    public func write() {
        var files = [FileGenerator]()
        languages.forEach({ (language) in
            switch language {
            case .objectiveC:
                files += ObjectiveCCategoryExtensions.generators()
            default:
                return
            }
        })

        files.forEach { (file) in
            writeFile(file: file, outputDirectory: outputDirectory, generationParameters: generationParameters)
        }
    }
    
    static func imports(for generationParameters: GenerationParameters, language: Languages) -> [String] {
        switch language {
        case .objectiveC:
            return [
                ObjectiveCCategoryExtensions.NSURLComponents.fullName
            ]
        default:
            return []
        }
    }

}

// MARK: Objective-C

extension UtilitySourceIncluder {
    
    class ObjectiveCCategoryExtensions {
        
        // Enlist different generators here i.e. [one list] + NSURLComponents.extensions + ...
        class func generators() -> [FileGenerator] {
            return NSURLComponents.extensions()
        }
        
        public class NSURLComponents {
            
            static let className = "NSURLComponents"
            static let categoryName = "PlankUtility"
            static let fullName = "\(NSURLComponents.className)+\(NSURLComponents.categoryName)"
            
            class func extensions() -> [FileGenerator] {
                let fileNameBase = "\(NSURLComponents.className)+\(NSURLComponents.categoryName)"

                let categoryMethods: [ObjCIR.Method] = [
                    NSURLComponents.NSURLComponentsUnsafeInitializer()
                ]
                
                let categoryRoots = [
                    ObjCIR.Root.imports(classNames: Set([NSURLComponents.fullName]), myName: NSURLComponents.fullName, parentName: nil),
                    ObjCIR.Root.categoryDecl(className: NSURLComponents.className,
                                             categoryName: NSURLComponents.categoryName,
                                             methods: categoryMethods,
                                             properties: [],
                                             headerOnly: true),
                    ObjCIR.Root.categoryImpl(className: NSURLComponents.className,
                                             categoryName: NSURLComponents.categoryName,
                                             methods: categoryMethods)
                ]
                
                let files: [FileGenerator] = [
                    ObjCHeaderFile(roots: categoryRoots, className: fileNameBase),
                    ObjCImplementationFile(roots: categoryRoots, className: fileNameBase)
                ]
                return files
            }
            
            class func NSURLComponentsUnsafeInitializer() -> ObjCIR.Method {
                return ObjCIR.method("+ (NSURL * _Nullable)URLWithUnsafeString:(NSString * _Nonnull)unsafeString", body: { () -> [String] in
                    return [
                        "static NSCharacterSet * fragmentDefinition;",
                        ObjCIR.ifStmt("fragmentDefinition == nil", body: { () -> [String] in
                            return [ "fragmentDefinition = [NSCharacterSet characterSetWithCharactersInString:@\"#\"];" ]
                        }),
                        "NSRange firstFragmentRange = [unsafeString rangeOfCharacterFromSet:fragmentDefinition];",
                        ObjCIR.ifStmt("firstFragmentRange.location != NSNotFound") {
                            return [
                                "NSString *baseURL = [unsafeString substringToIndex:firstFragmentRange.location];",
                                "NSString *fragment = [unsafeString substringFromIndex:firstFragmentRange.location];",
                                ObjCIR.ifStmt("fragment.length <= 1", body: { () -> [String] in
                                    return ["unsafeString = baseURL;"]
                                }),
                                ObjCIR.elseStmt({ () -> [String] in
                                    return ["fragment = [unsafeString substringFromIndex:(firstFragmentRange.location+1)];"]
                                }),
                                ObjCIR.ifStmt("[fragment rangeOfCharacterFromSet:fragmentDefinition].location != NSNotFound", body: { () -> [String] in
                                    return [
                                        "fragment = [fragment stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];",
                                    ]
                                }),
                                "unsafeString = [NSString stringWithFormat:@\"%@#%@\", baseURL, fragment];"
                            ]
                        },
                        "return [NSURLComponents componentsWithString:unsafeString].URL;"
                    ]
                })
            }
            
        }
    
        
    }
    
}
