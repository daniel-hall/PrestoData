//
// NSArray+PrestoData.m
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


#import <objc/runtime.h>
#import "NSString+_PrestoData_Internal.h"
#import "NSMutableDictionary+PrestoData.h"
#import "NSMutableDictionary+_PrestoData_Internal.h"
#import "NSArray+_PrestoData_Internal.h"
#import "NSArray+PrestoData.h"
#import "PrestoData.h"


@implementation NSArray (PrestoData)


+ (instancetype)pd_arrayFromJSONData:(NSData *)jsonData
{
    return [self pd_arrayFromJSONData:jsonData keyForInnerValue:defaultInnerValueKey];
}


+ (instancetype)pd_arrayFromJSONData:(NSData *)jsonData keyForInnerValue:(NSString *)key
{
    if(jsonData == nil)
    {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSArray *array = nil;

    if ([jsonString pd_isJSONArrayValue]) {

        array = [jsonString pd_extractJSONArrayValue];

        for (NSMutableDictionary *dictionary in array) {
            [dictionary pd_setParsedDictionaryPropertiesWithInnerValueKey:key];
        }
    }

    return array;
}

- (instancetype)pd_setValue:(id)value forAttribute:(NSString *)attribute
{
    for (NSMutableDictionary *dictionary in self)
    {
        [dictionary pd_setValue:value forAttribute:attribute];
    }

    return self;
}

- (instancetype)pd_setInnerValue:(id)value
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_setInnerValue:value];
    }

    return self;
}

- (void)pd_removeFromParentDictionary
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_removeFromParentDictionary];
    }
}

- (instancetype)pd_addElement:(NSMutableDictionary *)element withName:(NSString *)name
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_addElement:element withName:name];
    }

    return self;
}

- (instancetype)pd_removeElementNamed:(NSString *)elementName
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_removeElementNamed:elementName];
    }

    return self;
}

- (instancetype)pd_removeElement:(NSMutableDictionary *)element
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_removeElement:element];
    }

    return self;
}

- (instancetype)pd_deleteAttribute:(NSString *)attribute
{
    for (NSMutableDictionary *dictionary in self) {
        [dictionary pd_deleteAttribute:attribute];
    }

    return self;
}

- (NSArray *)pd_childrenNamed:(NSString *)name
{
    NSMutableArray *children = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *child in self) {
        NSArray *childChildren = [child pd_childrenNamed:name];
        if (childChildren) {
            [children addObjectsFromArray:childChildren];
        }
    }

    return children.count > 0 ? children : nil;
}

- (NSArray *)pd_descendantsNamed:(NSString *)name
{
    NSMutableArray *descendants = [[NSMutableArray alloc] init];

    for (NSMutableDictionary *child in self) {
        NSArray *childDescendants = [child pd_descendantsNamed:name];
        if (childDescendants) {
            [descendants addObjectsFromArray:childDescendants];
        }
    }

    return descendants.count > 0 ? descendants : nil;
}

- (NSArray *)pd_filterWithXPath:(NSString *)xPathString
{
    if (!xPathString || !xPathString.length) {
        return self;
    }

    NSMutableArray *filteredResults = [[NSMutableArray alloc] init];
    NSString *query = [xPathString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Parse out grouped expressions from parentheses first

    NSString *grouping = [query pd_extractInitialGroupingWithRemainder:&query];

    if (grouping) {
        return [[self pd_filterWithXPath:grouping] pd_filterWithXPath:query];
    }

    // If the first part of the XPath query is selecting a child or descendant, return that result filtered by the rest of the query

    NSString *element = [query pd_extractFirstXPathDescendantWithRemainder:&query];

    if (element) {
        for (NSMutableDictionary *child in self) {
            NSArray *results = [[child pd_descendantsNamed:element] pd_filterWithXPath:query];
            if (results) {
                [filteredResults addObjectsFromArray:results];
            }
        }
        return filteredResults.count ? filteredResults : nil;
    }

    element = [query pd_extractFirstXPathChildWithRemainder:&query];

    if (element)
    {
        for (NSMutableDictionary *child in self)
        {
            NSArray *results = [[child pd_childrenNamed:element] pd_filterWithXPath:query];
            if (results)
            {
                [filteredResults addObjectsFromArray:results];
            }
        }
        return filteredResults.count ? filteredResults : nil;
    }

    // Otherwise, check if it's a predicate for filtering

    NSString *predicate = [query pd_extractXPathPredicateWithRemainder:&query];

    if (predicate) {
        if ([predicate pd_isXPathAttributePredicate])
        {
            //Handle attribute query
            for (NSMutableDictionary *child in self) {
                NSArray *childResults = [[child pd_filterWithXPath:predicate] pd_filterWithXPath:query];
                if (childResults) {
                    [filteredResults addObjectsFromArray:childResults];
                }
            }
        }

        else {
            predicate = [predicate stringByReplacingOccurrencesOfString:@"last()" withString:@(self.count).stringValue];
            NSExpression *expression = [predicate pd_xpathPredicateNumericExpression];

            // If the predicate can be evaluated as an expression that returns a number, then evaluate it as use the resulting number as an index for retrieving a child element
            if(expression)
            {
                NSNumber *index = [expression expressionValueWithObject:nil context:nil];
                // XPath uses 1-based indexes
                NSNumber *xPathIndex = @(index.integerValue - 1);

                if (xPathIndex && xPathIndex.integerValue >= 0 && xPathIndex.unsignedIntegerValue < self.count) {
                    [filteredResults addObject:self[xPathIndex.unsignedIntegerValue]];
                }
            }

            // Otherwise, check if the predicate using the position() function in a comparison and evaluate the index of each child against it

            else if ([predicate pd_isXPathPositionPredicate])
            {
                for (NSInteger i = 0; i < self.count; i++) {
                    NSPredicate *comparison = [NSPredicate predicateWithFormat:[predicate pd_positionComparisonStringFromXPathPredicateUsingIndex:i]];
                    if ([comparison evaluateWithObject:nil]) {
                        [filteredResults addObject:self[i]];
                    }
                }
            }

            // So the only other type of predicate we care about checks for a child with a matching value
            else {
                for (NSMutableDictionary *child in self) {
                    NSArray *childResults = [[child pd_filterWithXPath:predicate] pd_filterWithXPath:query];
                    if (childResults) {
                        [filteredResults addObjectsFromArray:childResults];
                    }
                }
            }

        }
    }

    // This is where anything that isn't an element selector (/ or //) or a predicate expression ([]) would end up

    return filteredResults.count ? filteredResults : nil;
}

- (NSString *)pd_description
{
    NSString *tabs = @"";
    NSMutableDictionary *parentDictionary = self.pd_parentDictionary;
    while (parentDictionary != nil) {
        tabs = [tabs stringByAppendingString:@"\t"];
        parentDictionary = parentDictionary.pd_parentDictionary;
    }

    NSString *description = @"(\n";
    for (NSMutableDictionary *child in self) {
        description = [description stringByAppendingString:[NSString stringWithFormat:@"%@%@%@", tabs, child.pd_elementName ? [NSString stringWithFormat:@"(%@)", child.pd_elementName] : @"", child.pd_description]];
    }
    description = [description stringByAppendingString:[NSString stringWithFormat:@"%@)\n", tabs]];
    return description;
}

- (BOOL)pd_isEqualToArray:(NSArray *)array
{
    if (array == nil || ![array isKindOfClass:[NSArray class]])
    {
        NSLog(@"ARRAY NOT EQUAL BECAUSE COMPARED OBJECT IS NIL OR NOT AN ARRAY");
        return NO;
    }

    if (self.count != array.count)
    {
        NSLog(@"ARRAY NOT EQUAL BECAUSE DIFFERENT ELEMENT COUNTS.  %@ vs. %@", @(self.count), @(array.count));
        return NO;
    }

    for (NSUInteger i = 0; i < self.count; i++)
    {
        if (![self[i] pd_isEqualToDictionary:array[i]])
        {
            return NO;
        }
    }

    return YES;
}

- (NSString *)pd_jsonString {
    return [self pd_jsonStringWithInnerValueKey:defaultInnerValueKey];
}

- (NSString *)pd_jsonStringWithInnerValueKey:(NSString *)keyForInnerValue
{
    NSString *tabs = @"";
    NSMutableDictionary *parentDictionary = self.pd_parentDictionary;
    while (parentDictionary != nil) {
        tabs = [tabs stringByAppendingString:@"\t"];
        parentDictionary = parentDictionary.pd_parentDictionary;
    }

    NSString *result = @"[\n";
    for (NSMutableDictionary *dictionary in self) {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@", tabs, [dictionary pd_jsonStringWithInnerValueKey:keyForInnerValue]]];
        result = [result stringByAppendingString:@",\n"];
    }
    result = [result substringToIndex:result.length-2];
    result = [result stringByAppendingString:@"\n"];
    result = [result stringByAppendingString:[NSString stringWithFormat:@"%@]", tabs]];
    return result;
}

- (NSString *)pd_xmlString
{
    NSString *result = @"";
    for (NSMutableDictionary *dictionary in self)
    {
        result = [result stringByAppendingString:[dictionary pd_xmlString]];
    }
    return result;
}

- (instancetype)pd_copy {
    NSMutableArray *copy = [NSMutableArray arrayWithCapacity:self.count];
    for (NSMutableDictionary *dictionary in self) {
        [copy addObject:[dictionary pd_copy]];
    }
    return copy;
}

@end
