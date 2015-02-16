//
// NSString+_PrestoData_Internal.m
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



#import "NSString+_PrestoData_Internal.h"
#import "NSCharacterSet+_PrestoData_Internal.h"
#import "NSMutableDictionary+_PrestoData_Internal.h"
#import "NSMutableDictionary+PrestoData.h"

@implementation NSString (_PrestoData_Internal)


- (BOOL)pd_matchesWildcardedString:(NSString *)string
{
    
    NSString *wildcardedString = [string stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
    wildcardedString = [wildcardedString stringByReplacingOccurrencesOfString:@"?" withString:@".?"];
    BOOL isMatch = [self rangeOfString:wildcardedString options:NSRegularExpressionSearch].length == self.length;
    return isMatch;
}

- (NSString *)pd_extractInitialGroupingWithRemainder:(NSString **)remainingString
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *grouping = @"";
    
    if(![[target substringToIndex:1] isEqualToString:@"("])
    {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:target];
    NSCharacterSet *parentheses = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    scanner.scanLocation = 1;
    NSUInteger openCount = 1;
    
    while (scanner.scanLocation < target.length && openCount)
    {
        NSString *scannedCharacters = nil;
        if([scanner scanUpToCharactersFromSet:parentheses intoString:&scannedCharacters])
        {
            NSString *nextCharacter = [target substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
            if ([nextCharacter isEqualToString:@"("])
            {
                openCount++;
            }
            else if ([nextCharacter isEqualToString:@")"])
            {
                openCount--;
            }
            
            if (scannedCharacters)
            {
                grouping = [grouping stringByAppendingString:scannedCharacters];
            }
            
            if(openCount)
            {
                grouping = [grouping stringByAppendingString:nextCharacter];
            }
            
            scanner.scanLocation++;
        }
    }
    
    if (openCount)
    {
        return nil;
    }
    
    *remainingString = [target substringWithRange:NSMakeRange(scanner.scanLocation, target.length - scanner.scanLocation)];
    
    return grouping.length ? grouping : nil;
}


- (NSString *)pd_extractFirstXPathDescendantWithRemainder:(NSString **)remainingString
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(![[target substringToIndex:2] isEqualToString:@"//"])
    {
        return nil;
    }
    
    return [self pd_extractFirstXPathChildWithRemainder:remainingString];
}


- (NSString *)pd_extractFirstXPathChildWithRemainder:(NSString **)remainingString
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([[target substringToIndex:1] isEqualToString:@"["])
    {
        return nil;
    }
    
    NSString *child = @"";
    
    NSScanner *scanner = [NSScanner scannerWithString:target];
    NSCharacterSet *endCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/["];
    
    while(scanner.scanLocation < target.length && [[target substringWithRange:NSMakeRange(scanner.scanLocation, 1)] isEqualToString:@"/"])
    {
        scanner.scanLocation++;
    }
    
    [scanner scanUpToCharactersFromSet:endCharacters intoString:&child];
    
    if (scanner.scanLocation >= target.length)
    {
        *remainingString = nil;
    }
    
    else
    {
        *remainingString = [target substringWithRange:NSMakeRange(scanner.scanLocation, target.length - scanner.scanLocation)];
    }
    
    return child.length ? child : nil;
}

- (NSString *)pd_extractXPathPredicateWithRemainder:(NSString **)remainingString
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(![[target substringToIndex:1] isEqualToString:@"["])
    {
        return nil;
    }
    
    NSString *predicate = @"";
    
    NSScanner *scanner = [NSScanner scannerWithString:target];
    NSCharacterSet *endCharacter = [NSCharacterSet characterSetWithCharactersInString:@"]"];
    
    [scanner scanUpToCharactersFromSet:endCharacter intoString:&predicate];
    predicate = [predicate stringByAppendingString:[target substringWithRange:NSMakeRange(scanner.scanLocation, 1)]];
    scanner.scanLocation++;
    
    if (scanner.scanLocation >= target.length)
    {
        *remainingString = nil;
    }
    
    else
    {
        *remainingString = [target substringWithRange:NSMakeRange(scanner.scanLocation, target.length - scanner.scanLocation)];
    }
    
    return predicate.length ? predicate : nil;
}

- (BOOL)pd_isXPathAttributePredicate
{
    NSString *target = [self pd_stringByTrimmingXPathPredicateString];
    
    return [[target substringToIndex:1] isEqualToString:@"@"];
}


- (BOOL)pd_isXPathComparisonPredicate
{
    NSCharacterSet *operators = [NSCharacterSet characterSetWithCharactersInString:@"=!><"];
    return [self rangeOfCharacterFromSet:operators].length > 0;
}


- (BOOL)pd_isXPathPositionPredicate
{
    return [self pd_isXPathComparisonPredicate] && [self rangeOfString:@"position()" options:NSCaseInsensitiveSearch].length > 0;
}


- (NSUInteger)pd_indexOfOperatorInXPathPredicate
{
    return [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"=!><"]].location;
}


- (NSString *)pd_attributeFromXPathPredicate
{
    if (![self pd_isXPathAttributePredicate])
    {
        return nil;
    }
    
    NSString *target = [self pd_stringByTrimmingXPathPredicateString];
    NSString *attribute = nil;
    if ([self pd_indexOfOperatorInXPathPredicate] != NSNotFound)
    {
        attribute = [target substringWithRange:NSMakeRange(1, [self pd_indexOfOperatorInXPathPredicate] - 2)];
    }
    
    else
    {
        attribute = [target substringWithRange:NSMakeRange(1, target.length - 1)];
    }
    
    attribute = [attribute stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return attribute.length ? attribute : nil;
}

- (NSString *)pd_elementFromXPathPredicate
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *element;
    
    NSScanner* scanner = [NSScanner scannerWithString:target];
    NSCharacterSet *startCharacter = [NSCharacterSet characterSetWithCharactersInString:@"["];
    NSCharacterSet *endCharacters = [NSCharacterSet characterSetWithCharactersInString:@"!=<>]"];
    
    [scanner scanUpToCharactersFromSet:startCharacter intoString:nil];
    scanner.scanLocation++;
    [scanner scanUpToCharactersFromSet:endCharacters intoString:&element];
    
    return [element stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)pd_comparisonStringFromXPathPredicate
{
    NSString *target = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *comparison;
    
    if (![target pd_isXPathComparisonPredicate])
    {
        return nil;
    }
    
    NSCharacterSet *endPredicate = [NSCharacterSet characterSetWithCharactersInString:@"]"];
    NSScanner* scanner = [NSScanner scannerWithString:target];
    scanner.scanLocation = [target pd_indexOfOperatorInXPathPredicate];
    [scanner scanUpToCharactersFromSet:endPredicate intoString:&comparison];
    
    return [comparison stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)pd_positionComparisonStringFromXPathPredicateUsingIndex:(NSUInteger)index
{
    NSString *target = [self pd_stringByTrimmingXPathPredicateString];
    if (![target pd_isXPathPositionPredicate])
    {
        return nil;
    }
    
    target = [target stringByReplacingOccurrencesOfString:@"position()" withString:@(index + 1).stringValue options:NSCaseInsensitiveSearch range:NSMakeRange(0, target.length)];
    
    return target;
}

- (BOOL)pd_isXPathPredicateNumericExpression
{
    NSMutableCharacterSet *skipCharacters = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789+-.()*/[]"];
    [skipCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *skip = [skipCharacters copy];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    NSString *scannedString = nil;
    [scanner setCharactersToBeSkipped:skip];
    [scanner scanCharactersFromSet:skip.invertedSet intoString:&scannedString];
    return !scannedString.length;
}

- (NSExpression *)pd_xpathPredicateNumericExpression
{
    if (![self pd_isXPathPredicateNumericExpression] || [self pd_isXPathComparisonPredicate])
    {
        return nil;
    }
    NSString *predicateString = [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
    predicateString = [predicateString stringByAppendingString:@"= 0"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    return [(NSComparisonPredicate *)predicate leftExpression];
}

- (NSString *)pd_stringByTrimmingXPathPredicateString
{
    NSMutableCharacterSet *toTrim = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [toTrim formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
    return [self stringByTrimmingCharactersInSet:[toTrim copy]];
}

- (NSString *)pd_extractNextJSONKeyWithRemainder:(NSString **)remainingString
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndCommaCharacterSet]];
    NSString *key = nil;
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    [scanner scanUpToString:@"\"" intoString:nil];
    
    if (scanner.scanLocation + 2 >= trimmed.length)
    {
        return nil;
    }
    
    scanner.scanLocation++;
    [scanner scanUpToString:@"\"" intoString:&key];
    
    if ([scanner scanUpToString:@":" intoString:nil] && key)
    {
        scanner.scanLocation = scanner.scanLocation < trimmed.length - 1 ? scanner.scanLocation + 1 : scanner.scanLocation;
        *remainingString = [[trimmed substringWithRange:NSMakeRange(scanner.scanLocation, trimmed.length - scanner.scanLocation)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndCommaCharacterSet]];
        return key;
    }
    
    return nil;
}


- (NSString *)pd_extractNextJSONValueStringWithRemainder:(NSString **)remainingString
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!trimmed.length)
    {
        return nil;
    }
    
    NSUInteger endLocation = NSNotFound;
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    scanner.scanLocation = scanner.scanLocation < trimmed.length - 1 ? scanner.scanLocation + 1 : scanner.scanLocation;
    
    if([trimmed pd_isJSONStringValue]) {
        if ([[trimmed substringToIndex:2] isEqualToString:@"\"\""]) {
            *remainingString = trimmed.length > 2 ? [trimmed substringWithRange:NSMakeRange(2, trimmed.length - 2)] : nil;
            return @"\"\"";
        }

        while (endLocation == NSNotFound && [scanner scanUpToString:@"\"" intoString:nil]) {
            if (![[trimmed substringWithRange:NSMakeRange(scanner.scanLocation - 1, 1)] isEqualToString:@"\\"]) {
                endLocation = scanner.scanLocation;
            }

            scanner.scanLocation++;
        }
    }

    else if ([trimmed pd_isJSONNumberValue]){
        scanner.scanLocation = 0;
        NSRange rangeOfComma = [trimmed rangeOfString:@","];
        if (rangeOfComma.length == 0) {
            *remainingString = nil;
            return trimmed;
        }

        while (endLocation == NSNotFound && [scanner scanUpToString:@"," intoString:nil]) {
            endLocation = scanner.scanLocation;
        }
    }
    
    else
    {
        if ([self pd_isJSONDictionaryValue])
        {
            NSCharacterSet *valueWrappers= [NSCharacterSet characterSetWithCharactersInString:@"{}"];
            NSUInteger openCount = 1;
            
            while (endLocation == NSNotFound && openCount && [scanner scanUpToCharactersFromSet:valueWrappers intoString:nil])
            {
                if ([[trimmed substringWithRange:NSMakeRange(scanner.scanLocation, 1)] isEqualToString:@"}"])
                {
                    openCount--;
                }
                else
                {
                    openCount++;
                }
                
                if (!openCount)
                {
                    endLocation = scanner.scanLocation;
                }
                
                scanner.scanLocation++;
            }
        }
        
        else if ([self pd_isJSONArrayValue])
        {
            NSCharacterSet *valueWrappers = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
            NSUInteger openCount = 1;
            
            while (endLocation == NSNotFound && openCount && [scanner scanUpToCharactersFromSet:valueWrappers intoString:nil]) {
                if ([[trimmed substringWithRange:NSMakeRange(scanner.scanLocation, 1)] isEqualToString:@"]"])
                {
                    openCount--;
                }
                else
                {
                    openCount++;
                }
                
                if (!openCount)
                {
                    endLocation = scanner.scanLocation;
                }
                
                scanner.scanLocation++;
            }
        }
    }
    
    if (endLocation == NSNotFound) {
        return nil;
    }
    endLocation++;
    *remainingString = trimmed.length > endLocation + 1 ? [[trimmed substringWithRange:NSMakeRange(endLocation, trimmed.length - endLocation)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndCommaCharacterSet]] : nil;
    NSString *value = [[trimmed substringWithRange:NSMakeRange(0, endLocation)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndCommaCharacterSet]];
    return value.length ? value : nil;
}

- (BOOL)pd_isJSONDictionaryValue
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length ? [[trimmed substringToIndex:1] isEqualToString:@"{"] : NO;
}


- (BOOL)pd_isJSONArrayValue
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length ? [[trimmed substringToIndex:1] isEqualToString:@"["] : NO;
}


- (BOOL)pd_isJSONStringValue
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length ? [[trimmed substringToIndex:1] isEqualToString:@"\""] : NO;
}


- (BOOL)pd_isJSONNumberValue
{
    NSString *trimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    trimmed = [trimmed rangeOfString:@","].length ? [trimmed substringToIndex:[trimmed rangeOfString:@","].location] : trimmed;
    if ([trimmed isEqualToString:@"true"] || [trimmed isEqualToString:@"false"]) {
        return YES;
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *number = [formatter numberFromString:trimmed];
    return number != nil;
}


- (NSMutableDictionary *)pd_extractJSONDictionaryValue
{
    NSString *trimmed = [[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *key = [trimmed pd_extractNextJSONKeyWithRemainder:&trimmed];
    NSString *value = [trimmed pd_extractNextJSONValueStringWithRemainder:&trimmed];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    while(key && value)
    {
        if ([value pd_isJSONDictionaryValue])
        {
            NSMutableDictionary *dictionaryValue = [value pd_extractJSONDictionaryValue];
            if (dictionaryValue && (dictionaryValue.pd_orderedKeys.count || dictionaryValue.pd_innerValue))
            {
                [dictionary pd_addElement:dictionaryValue withName:key];
            }
        }

        if ([value pd_isJSONArrayValue])
        {
            NSArray *arrayValue = [value pd_extractJSONArrayValue];

            if (arrayValue != nil && arrayValue.count > 0) {
                [dictionary pd_addElement:(id) [NSMutableArray array] withName:key];
            }

            for (NSMutableDictionary *dictionaryElement in arrayValue)
            {
                if (dictionaryElement)
                {
                    [dictionary pd_addElement:dictionaryElement withName:key];
                }
            }
        }
        
        if ([value pd_isJSONStringValue])
        {
            NSString *valueString = [value pd_extractJSONStringValue];
            if (valueString)
            {
                [dictionary pd_setValue:valueString forAttribute:key];
            }
        }

        if ([value pd_isJSONNumberValue])
        {
            NSNumber *valueNumber = [value pd_extractJSONNumberValue];
            if (valueNumber)
            {
                [dictionary pd_setValue:valueNumber forAttribute:key];
            }
        }
        
        key = [trimmed pd_extractNextJSONKeyWithRemainder:&trimmed];
        value = [trimmed pd_extractNextJSONValueStringWithRemainder:&trimmed];
    }
    
    return dictionary.pd_orderedKeys.count || dictionary.pd_innerValue ? dictionary : nil;
}


- (NSArray *)pd_extractJSONArrayValue
{
    NSString *trimmed = [[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *value = [trimmed pd_extractNextJSONValueStringWithRemainder:&trimmed];
    NSMutableArray *array = [NSMutableArray array];
    
    while(value)
    {
        if([value pd_isJSONDictionaryValue])
        {
            NSMutableDictionary *dictionary = [value pd_extractJSONDictionaryValue];
            if (dictionary)
            {
                [array addObject:dictionary];
            }
        }
        
        else if ([value pd_isJSONStringValue])
        {
            NSString *stringValue = [value pd_extractJSONStringValue];
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            if (stringValue && stringValue.length)
            {
                [dictionary pd_setInnerValue:stringValue];
            }
            
            if (dictionary)
            {
                [array addObject:dictionary];
            }
        }

        else if ([value pd_isJSONNumberValue])
        {
            NSNumber *numberValue = [value pd_extractJSONNumberValue];
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

            if (numberValue)
            {
                [dictionary pd_setInnerValue:numberValue];
            }

            if (dictionary)
            {
                [array addObject:dictionary];
            }
        }

        value = [trimmed pd_extractNextJSONValueStringWithRemainder:&trimmed];
    }
    
    return array.count ? array : nil;
}


- (NSString *)pd_extractJSONStringValue
{
    NSString *trimmed = [[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed;
}

- (NSNumber *)pd_extractJSONNumberValue
{
    NSString *trimmed = [[[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [trimmed isEqualToString:@"true"] || [trimmed isEqualToString:@"false"] ? @([trimmed boolValue]) : @([trimmed doubleValue]);
}


@end
