//
// NSMutableDictionary+PrestoData.m
//
// Copyright (c) 2015 Daniel Hall
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


#import "NSMutableDictionary+PrestoData.h"
#import "NSString+_PrestoData_Internal.h"
#import "NSMutableDictionary+_PrestoData_Internal.h"
#import "NSArray+_PrestoData_Internal.h"
#import "NSArray+PrestoData.h"
#import "PrestoData.h"
#import <objc/runtime.h>

@interface PDXMLToDictionaryParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSMutableDictionary *currentDictionary;
@property (nonatomic, strong) NSMutableDictionary *rootDictionary;

@end

@implementation PDXMLToDictionaryParser

- (instancetype) initWithXMLData:(NSData *)data
{
    self = [super init];
    
    if (self) {
        self.data = data;
    }
    
    return self;
}

- (NSMutableDictionary *) parsedDictionary
{
    if (self.data == nil) {
        return nil;
    }
    self.rootDictionary = [NSMutableDictionary dictionary];
    self.currentDictionary = self.rootDictionary;
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.data];
    
    parser.delegate = self;
    BOOL success = [parser parse];
    
    if (success){
        return self.currentDictionary;
    }
    
    else {
        return nil;
    }
}


#pragma mark -  NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSMutableDictionary *newDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in attributeDict.allKeys)
    {
        [newDictionary pd_setValue:attributeDict[key] forAttribute:key];
    }
    
    newDictionary.pd_innerValue = [[NSMutableString alloc] init];

    [self.currentDictionary pd_addElement:newDictionary withName:elementName];
    self.currentDictionary = newDictionary;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    self.currentDictionary.pd_innerValue = [self.currentDictionary.pd_innerValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (((NSString *) self.currentDictionary.pd_innerValue).length == 0)
    {
        self.currentDictionary.pd_innerValue = nil;
    }

    else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *numberResult = [formatter numberFromString:((NSString *) self.currentDictionary.pd_innerValue)];
        if (numberResult) {
            self.currentDictionary.pd_innerValue = numberResult;
        }
    }

    self.currentDictionary = self.currentDictionary.pd_parentDictionary ? : self.currentDictionary;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    self.currentDictionary.pd_innerValue = [self.currentDictionary.pd_innerValue stringByAppendingString:string];
}


@end


@implementation NSMutableDictionary (PrestoData)

+ (instancetype)pd_dictionaryFromXMLData:(NSData *)xmlData
{
    PDXMLToDictionaryParser *parser = [[PDXMLToDictionaryParser alloc] initWithXMLData:xmlData];
    return [parser parsedDictionary];
}

+ (instancetype)pd_dictionaryFromJSONData:(NSData *)jsonData
{
    return [self pd_dictionaryFromJSONData:jsonData keyForInnerValue:defaultInnerValueKey];
}


+ (instancetype)pd_dictionaryFromJSONData:(NSData *)jsonData keyForInnerValue:(NSString *)key
{
    if(jsonData == nil)
    {
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *dictionary = [jsonString pd_extractJSONDictionaryValue];
    [dictionary pd_setParsedDictionaryPropertiesWithInnerValueKey:key];
    return dictionary;
}


- (NSString *)pd_innerValue
{
    return objc_getAssociatedObject(self, @selector(pd_innerValue));
}


- (NSMutableDictionary *)pd_parentDictionary
{
    return objc_getAssociatedObject(self, @selector(pd_parentDictionary));
}


- (NSString *)pd_elementName
{
    return objc_getAssociatedObject(self, @selector(pd_elementName));
}

- (NSArray *)pd_orderedKeys
{
    return [self privateOrderedKeys];
}


- (NSMutableArray *)privateOrderedKeys
{
    NSMutableArray *keys = objc_getAssociatedObject(self, @selector(pd_orderedKeys));
    if (keys == nil) {
        keys = [NSMutableArray array];
        objc_setAssociatedObject(self, @selector(pd_orderedKeys), keys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return keys;
}

- (instancetype)pd_setValue:(id)value forAttribute:(NSString *)attribute
{
    if (!value || ([value isKindOfClass:[NSString class]] && !((NSString *) value).length) || !attribute || !attribute.length)
    {
        return self;
    }
    
    if (!self[attribute])
    {
        [[self privateOrderedKeys] addObject:attribute];
    }
    
    self[attribute] = value;
    return self;
}

- (instancetype)pd_deleteAttribute:(NSString *)attribute
{
    if (!attribute || !attribute.length)
    {
        return self;
    }
    
    if (self[attribute])
    {
        [[self privateOrderedKeys] removeObject:attribute];
        [self removeObjectForKey:attribute];
    }
    return self;

}

- (instancetype)pd_setInnerValue:(id)value
{
    self.pd_innerValue = value;
    return self;
}

- (void)pd_removeFromParentDictionary
{
    [self.pd_parentDictionary pd_removeElementNamed:self.pd_elementName];
}

- (instancetype)pd_addElement:(NSMutableDictionary *)element withName:(NSString *)name
{
    if (element == nil)
    {
        return self;
    }
    
    element.pd_elementName = name;
    element.pd_parentDictionary = self;
    id existingValue = self[name];
    
    if(existingValue)
    {
        if (![existingValue isKindOfClass:[NSArray class]]) {
            existingValue = [@[existingValue] mutableCopy];
            ((NSArray *)existingValue).pd_elementName = name;
            ((NSArray *)existingValue).pd_parentDictionary = self;
            self[name] = existingValue;
        }
        
        [((NSMutableArray *)existingValue) addObject:element];
    }
    
    else
    {
        [[self privateOrderedKeys] addObject:name];
        self[name] = element;
    }
    return self;
}

- (instancetype)pd_removeElementNamed:(NSString *)elementName
{
    if (self[elementName])
    {
        [[self privateOrderedKeys] removeObject:elementName];
        [self removeObjectForKey:elementName];
    }
    return self;

}

- (instancetype)pd_removeElement:(NSMutableDictionary *)element
{
    id existingValue = self[element.pd_elementName];
    
    if(existingValue)
    {
        if ([existingValue isKindOfClass:[NSArray class]]) {
            if ([existingValue indexOfObject:element] != NSNotFound)
            {
                [existingValue removeObject:element];
            }
            if (((NSArray *)existingValue).count == 0)
            {
                [self pd_removeElementNamed:((NSArray *) existingValue).pd_elementName];
            }
        }
        else
        {
            [self pd_removeElementNamed:element.pd_elementName];
        }
    }
    return self;
}

- (NSString *)pd_description
{
    NSString *tabs = @"";
    NSMutableDictionary *parentDictionary = self.pd_parentDictionary;
    while (parentDictionary != nil)
    {
        tabs = [tabs stringByAppendingString:@"\t"];
        parentDictionary = parentDictionary.pd_parentDictionary;
    }
    NSString *description = @"{\n";
    
    for (NSString *key in self.pd_orderedKeys)
    {
        id value = self[key];
        if([value isKindOfClass:[NSString class]]) {
            description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@%@ = \"%@\"\n",tabs, @"\t",key, value]];
        }

        else if([value isKindOfClass:[NSNumber class]]) {
            description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@%@ = %@\n",tabs, @"\t",key, value]];
        }

        else if([value isKindOfClass:[NSArray class]]) {
            description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@%@ = %@",tabs, @"\t",key, [value pd_description]]];
        }
        else if([value isKindOfClass:[NSMutableDictionary class]]) {
            description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@%@ = %@",tabs, @"\t",key, [value pd_description]]];
        }
    }
    if ([self.pd_innerValue isKindOfClass:[NSString class]] && ((NSString *) self.pd_innerValue).length)
    {
        description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@pd_innerValue = \"%@\"\n", tabs, @"\t", self.pd_innerValue]];
    }
    else if ([self.pd_innerValue isKindOfClass:[NSNumber class]])
    {
        description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@pd_innerValue = %@\n", tabs, @"\t", self.pd_innerValue]];
    }
    description = [description stringByAppendingString:[NSString stringWithFormat:@"%@}\n", tabs]];
    return description;
}


- (NSArray *)pd_childrenNamed:(NSString *)name
{
    NSMutableArray *children = [[NSMutableArray alloc] init];
    
    for (NSString* key in self.pd_orderedKeys)
    {
        if ([key pd_matchesWildcardedString:[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]])
        {
            id value = self[key];
            if ([value isKindOfClass:[NSMutableDictionary class]])
            {
                [children addObject:self[key]];
            }
            else if ([value isKindOfClass:[NSArray class]])
            {
                [children addObjectsFromArray:value];
            }
        }
    }
    
    return children.count > 0 ? children : nil;
}


- (NSArray *)pd_descendantsNamed:(NSString *)name
{
    NSMutableArray *descendants = [[NSMutableArray alloc] init];
    
    NSArray *children = [self pd_childrenNamed:name];
    if (children)
    {
        [descendants addObjectsFromArray:children];
    }
    
    for (NSString *key in self.pd_orderedKeys)
    {
        id value = self[key];
        
        if ([value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]])
        {
            NSArray *valueDescendants = [value pd_descendantsNamed:name];
            if (valueDescendants)
            {
                [descendants addObjectsFromArray:valueDescendants];
            }
        }
    }
    
    return descendants.count > 0 ? descendants : nil;
}

-(NSArray *)pd_filterWithXPath:(NSString *)xPathString {
    
    if (!xPathString || !xPathString.length)
    {
        return @[self];
    }
    
    NSMutableArray *filteredResults = [[NSMutableArray alloc] init];
    NSString *query = [xPathString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Parse out grouped expressions from parentheses first
    
    NSString *grouping = [query pd_extractInitialGroupingWithRemainder:&query];
    
    if (grouping) {
        return [[self pd_filterWithXPath:grouping] pd_filterWithXPath:query];
    }
    
    // If the first part of the Xpath query is selecting a child or descendant, return that result filtered by the rest of the query
    
    NSString *element = [query pd_extractFirstXPathDescendantWithRemainder:&query];
    
    if (element)
    {
        NSArray *childResults = [[self pd_descendantsNamed:element] pd_filterWithXPath:query];
        if (childResults.count) {
            [filteredResults addObjectsFromArray:childResults];
        }
        
        return filteredResults.count ? filteredResults : nil;
    }
    
    element = [query pd_extractFirstXPathChildWithRemainder:&query];
    
    if (element)
    {
        NSArray *childResults = [[self pd_childrenNamed:element] pd_filterWithXPath:query];
        if (childResults.count) {
            [filteredResults addObjectsFromArray:childResults];
        }
        return filteredResults.count ? filteredResults : nil;
    }
    
    // Otherwise, check if it's a predicate for filtering
    
    NSString *predicate = [query pd_extractXPathPredicateWithRemainder:&query];
    
    if (predicate) {
        // Handle attribute-based predicates
        if ([predicate pd_isXPathAttributePredicate])
        {
            //Handle attribute predicates that compare attribute value to another value
            if ([predicate pd_isXPathComparisonPredicate])
            {
                NSString *attribute = [predicate pd_attributeFromXPathPredicate];
                NSString *comparisonString = [predicate pd_comparisonStringFromXPathPredicate];
                for (NSString *key in self.pd_orderedKeys) {
                    if ([self[key] isKindOfClass:[NSMutableDictionary class]] || [self[key] isKindOfClass:[NSArray class]]) {
                        continue;
                    }
                    NSString *value = [self[key] floatValue] ? self[key] : [NSString stringWithFormat:@"'%@'", self[key]];
                    if ([key pd_matchesWildcardedString:attribute]) {
                        NSString *predicateString = [NSString stringWithFormat:@"%@%@", value, comparisonString];
                        NSPredicate *comparison = [NSPredicate predicateWithFormat:predicateString];
                        if ([comparison evaluateWithObject:nil])
                        {
                            NSArray *myResults = [self pd_filterWithXPath:query];
                            if (myResults.count) {
                                [filteredResults addObject:self];
                            }
                        }
                    }
                }
            }
            
            else
            {
                // Otherwise, just check for attribute existence
                NSString *attribute = [predicate pd_attributeFromXPathPredicate];
                for (NSString *key in self.pd_orderedKeys)
                {
                    if ([self[key] isKindOfClass:[NSMutableDictionary class]]) {
                        continue;
                    }
                    if ([key pd_matchesWildcardedString:attribute])
                    {
                        NSArray *myResults = [self pd_filterWithXPath:query];
                        if (myResults.count) {
                            [filteredResults addObject:self];
                        }
                    }
                }
            }
        }
        
        else
        {
            //We don't handle index-based predicated within as single dictionary, those are handled only in the NSArray filtering category
            
            //Handle a predicate that compares a child value to another value
            if ([predicate pd_isXPathComparisonPredicate]) {
                NSString *predElement = [predicate pd_elementFromXPathPredicate];
                NSString *comparisonString = [predicate pd_comparisonStringFromXPathPredicate];
                for (NSString *key in self.pd_orderedKeys) {
                    NSMutableDictionary *child = self[key];
                    if (![child isKindOfClass:[NSMutableDictionary class]] || child.pd_innerValue == nil)
                    {
                        continue;
                    }
                    NSString *value = [child.pd_innerValue floatValue] ? child.pd_innerValue : [NSString stringWithFormat:@"'%@'", child.pd_innerValue];
                    if ([key pd_matchesWildcardedString:predElement]) {
                        NSString *predicateString = [NSString stringWithFormat:@"%@%@", value, comparisonString];
                        NSPredicate *comparison = [NSPredicate predicateWithFormat:predicateString];
                        if ([comparison evaluateWithObject:nil]) {
                            NSArray *myResults = [self pd_filterWithXPath:query];
                            if (myResults.count)
                            {
                                [filteredResults addObject:self];
                            }
                        }
                    }
                }
            }
            //Otherwise handle predicates that check only for the existence of a child (not attribute) with the specified name
            else {
                NSArray *childResults = [[self pd_childrenNamed:[predicate pd_elementFromXPathPredicate]] pd_filterWithXPath:query];
                if (childResults.count)
                {
                    [filteredResults addObjectsFromArray:childResults];
                }
            }
            
        }
    }
    
    
    return filteredResults.count ? filteredResults : nil;
}


- (BOOL)pd_isEqualToDictionary:(NSMutableDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSMutableDictionary class]])
    {
        NSLog(@"DICTIONARY NOT EQUAL BECAUSE OTHER DICTIONARY NOT NSDICTIONARY, CLASS = %@", [dictionary class]);
        return NO;
    }
    
    if (!(self.pd_orderedKeys.count == 0 && dictionary.pd_orderedKeys.count == 0) && ![self.pd_orderedKeys isEqualToArray:dictionary.pd_orderedKeys])
    {
        NSLog(@"DICTIONARY NOT EQUAL BECAUSE DIFFERENT ORDERED KEYS:  %@ vs. %@", self.pd_orderedKeys, dictionary.pd_orderedKeys);
        return NO;
    }
    
    if (!(self.pd_innerValue == nil && dictionary.pd_innerValue == nil) && ![self.pd_innerValue isEqual:dictionary.pd_innerValue])
    {
        NSLog(@"DICTIONARY NOT EQUAL BECAUSE DIFFERENT INNER VALUES:  %@ vs. %@", self.pd_innerValue, dictionary.pd_innerValue);
        return NO;
    }
    
    if (!(self.pd_elementName == nil && dictionary.pd_elementName == nil) && ![self.pd_elementName isEqual:dictionary.pd_elementName])
    {
        NSLog(@"DICTIONARY NOT EQUAL BECAUSE DIFFERENT ELEMENT NAME:  %@ vs. %@", self.pd_elementName, dictionary.pd_elementName);
        return NO;
    }
    
    for (NSString* key in self)
    {
        id myValue = self[key];
        id otherValue = dictionary[key];
        
        if ([myValue isKindOfClass:[NSMutableDictionary class]] && ![myValue pd_isEqualToDictionary:otherValue])
        {
            NSLog(@"DICTIONARY NOT EQUAL BECAUSE DIFFERENT NSMUTABLEDICTIONARY ELEMENT VALUES:  %@ vs. %@", [myValue pd_description], [otherValue pd_description]);
            return NO;
        }
        
        else if ([myValue isKindOfClass:[NSArray class]] && ![myValue pd_isEqualToArray:otherValue])
        {
            NSLog(@"DICTIONARY NOT EQUAL BECAUSE DIFFERENT NSARRAY ELEMENT VALUES:  %@ vs. %@", [myValue pd_description], [otherValue pd_description]);
            return NO;
        }
    }
    
    return YES;
}

- (NSString *)pd_jsonString
{
    return [self pd_jsonStringWithInnerValueKey:defaultInnerValueKey];
}


- (NSString *)pd_jsonStringWithInnerValueKey:(NSString *)keyForInnerValue
{
    NSString *tabs = @"";
    NSMutableDictionary *parentDictionary = self.pd_parentDictionary;
    while (parentDictionary != nil)
    {
        tabs = [tabs stringByAppendingString:@"\t"];
        parentDictionary = parentDictionary.pd_parentDictionary;
    }
    NSString *result = @"{\n";
    
    if (!self.pd_orderedKeys.count && self.pd_innerValue)
    {
        return [NSString stringWithFormat:@"%@", [self.pd_innerValue isKindOfClass:[NSNumber class]] ? self.pd_innerValue : [NSString stringWithFormat:@"\"%@\"", self.pd_innerValue]];
    }
    
    for (NSString *key in self.pd_orderedKeys)
    {
        id value = self[key];
        if([value isKindOfClass:[NSString class]]) {
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : \"%@\"",tabs, @"\t",key, value]];
        }

        else if([value isKindOfClass:[NSNumber class]]) {
            if ([[NSStringFromClass([value class]) lowercaseString] rangeOfString:@"bool"].length > 0) {
                result =  [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : %@",tabs, @"\t",key, [value boolValue] ? @"true" : @"false"]];
            }
            else {
                result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : %@",tabs, @"\t",key, value]];
            }
        }

        else if([value isKindOfClass:[NSArray class]]) {
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : %@",tabs, @"\t",key, [value pd_jsonStringWithInnerValueKey:keyForInnerValue]]];
        }
        else if([value isKindOfClass:[NSMutableDictionary class]]) {
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : %@",tabs, @"\t",key, [value pd_jsonStringWithInnerValueKey:keyForInnerValue]]];
        }
        
        result = [result stringByAppendingString:@",\n"];
    }
    
    if ([self.pd_innerValue isKindOfClass:[NSString class]] && ((NSString *) self.pd_innerValue).length > 0)
    {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : \"%@\"\n", tabs, @"\t", keyForInnerValue, self.pd_innerValue]];
    }

    else if ([self.pd_innerValue isKindOfClass:[NSNumber class]])
    {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@\"%@\" : %@\n", tabs, @"\t", keyForInnerValue, self.pd_innerValue]];
    }
    
    else
    {
        result = [result substringToIndex:result.length - 2];
        result = [result stringByAppendingString:@"\n"];
    }
    result = [result stringByAppendingString:[NSString stringWithFormat:@"%@}", tabs]];
    return result;
}


- (NSString *)pd_xmlString {
    
    NSString *tabs = @"";
    NSMutableDictionary *parentDictionary = self.pd_parentDictionary;
    while (parentDictionary != nil) {
        tabs = [tabs stringByAppendingString:@"\t"];
        parentDictionary = parentDictionary.pd_parentDictionary;
    }
    
    NSString *result = [NSString stringWithFormat:@"%@<%@ ", tabs, self.pd_elementName];
    
    NSUInteger attributeCount = 0;
    
    for (NSString *attributeName in self.pd_orderedKeys)
    {
        id attributeValue = self[attributeName];
        if (![attributeValue isKindOfClass:[NSString class]])
        {
            continue;
        }
        attributeCount++;
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@=\"%@\" ", attributeName, attributeValue]];
    }
    
    if (self.pd_orderedKeys.count == attributeCount && ([self.pd_innerValue isKindOfClass:[NSString class]] && ((NSString *) self.pd_innerValue).length == 0))
    {
        result = [result stringByAppendingString:@"/>\n"];
        return result;
    }
    
    else{
        result = [result substringToIndex:result.length-1];
        result = [result stringByAppendingString:@">\n"];
    }
    
    if (!self.pd_elementName)
    {
        result = @"";
    }
    
    for (NSString *key in self.pd_orderedKeys) {
        id value = self[key];
        
        if ([value isKindOfClass:[NSArray class]]) {
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@", [value pd_xmlString]]];
        }
        else if ([value isKindOfClass:[NSMutableDictionary class]]) {
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@", [value pd_xmlString]]];
        }
    }
    
    if (([self.pd_innerValue isKindOfClass:[NSString class]] && ((NSString *) self.pd_innerValue).length > 0)) {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@%@\n", tabs, @"\t", self.pd_innerValue]];
    }

    else if ([self.pd_innerValue isKindOfClass:[NSNumber class]]) {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@%@\n", tabs, @"\t", self.pd_innerValue]];
    }
    
    result = self.pd_elementName ? [result stringByAppendingString:[NSString stringWithFormat:@"%@</%@>\n", tabs, self.pd_elementName]] : result;
    return result;
}

- (instancetype)pd_copy
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionary];
    for (NSString *key in self.pd_orderedKeys) {
        id value = self[key];

        if ([value isKindOfClass:[NSArray class]]) {
            for (NSMutableDictionary *dictionary in value) {
                [copy pd_addElement:[dictionary pd_copy] withName:key];
            }
        }

        else if ([value isKindOfClass:[NSMutableDictionary class]]) {
            [copy pd_addElement:[value pd_copy] withName:key];
        }

        else {
            [copy pd_setValue:value forAttribute:key];
        }
    }

    copy.pd_innerValue = self.pd_innerValue;

    return copy;
}


@end
