//
//  DDXMLElementAdditions.h
//  Cinequest
//
//  Created by Luca Severini on 12/2/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "DDXML.h"

// These methods are not part of the standard NSXML API.
// But any developer working extensively with XML will likely appreciate them.

@interface DDXMLElement (DDAdditions)

+ (DDXMLElement *)elementWithName:(NSString *)name xmlns:(NSString *)ns;

- (DDXMLElement *)elementForName:(NSString *)name;
- (DDXMLElement *)elementForName:(NSString *)name xmlns:(NSString *)xmlns;

- (NSString *)xmlns;
- (void)setXmlns:(NSString *)ns;

- (void)addAttributeWithName:(NSString *)name stringValue:(NSString *)string;

//- (NSDictionary *)attributesAsDictionary;

@end
