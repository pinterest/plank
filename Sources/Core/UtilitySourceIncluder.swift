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

}

// MARK: Objective-C

extension UtilitySourceIncluder {
    
    class ObjectiveCCategoryExtensions {
        
        // Enlist different generators here i.e. [one list] + NSURLComponents.extensions + ...
        class func generators() -> [FileGenerator] {
            return NSURLComponents.extensions()
        }
        
        private class NSURLComponents {
            
            class func extensions() -> [FileGenerator] {
                let classToExtend = "NSURLComponents"
                let extensionName = "PlankUtility"
                let fileNameBase = "\(classToExtend)+\(extensionName)"

                let categoryMethods: [ObjCIR.Method] = [
                    NSURLComponents.NSURLComponentsUnsafeInitializer()
                ]
                
                let categoryRoots = [
                    ObjCIR.Root.category(className: classToExtend, categoryName: extensionName, methods: categoryMethods, properties: [])
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
                        "static NSCharacterSet * const fragmentDefinition = [NSCharacterSet characterSetWithCharactersInString:@\"#\"];",
                        "NSRange firstFragmentRange = [unsafeString rangeOfCharacterInSet:fragmentDefinition];",
                        ObjCIR.ifStmt("firstFragmentRange.location != NSNotFound") {
                            return [
                                "NSString *baseURL = [unsafeString substringToIndex:firstFragmentRange.location];",
                                "NSString *fragment = [unsafeString substringFromIndex:firstFragmentRange.location];",
                                ObjCIR.ifStmt("[unsafeString rangeOfCharacterInSet:fragmentDefinition].location != NSNotFound", body: { () -> [String] in
                                    return [
                                        "NSString *encodedFragment = [fragment stringByAddingPercentEncodingWithAllowedCharacters:URLFragmentAllowedCharacterSet];",
                                        "unsafeString = [NSStringWithFormat:@\"%@#%@\", baseUrl, encodedFragment];"
                                    ]
                                })
                            ]
                        },
                        "return [NSURLComponents urlComponentsWithString:unsafeString].URL;"
                    ]
                })
            }
            
        }
    
        
    }
    
}
