//
// PrestoData.m
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


#import "PrestoData.h"

NSString *const defaultInnerValueKey = @"innerValue";

@implementation PrestoData

+ (id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery withNewValue:(id)value forAttribute:(NSString *)attributeName {
    id jsonObject = [self dictionaryOrArrayLoadedFromJSON:filePath];

    if (xpathQuery) {
        [[jsonObject pd_filterWithXPath:xpathQuery] pd_setValue:value forAttribute:attributeName];
    }

    else {
        [jsonObject pd_setValue:value forAttribute:attributeName];
    }

    return jsonObject;
}

+ (id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery removingAttributeNamed:(NSString *)attributeName {
    id jsonObject = [self dictionaryOrArrayLoadedFromJSON:filePath];

    if (xpathQuery) {
        [[jsonObject pd_filterWithXPath:xpathQuery] pd_deleteAttribute:attributeName];
    }

    else {
        [jsonObject pd_deleteAttribute:attributeName];
    }

    return jsonObject;}

+ (id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery withNewElement:(NSMutableDictionary *)element named:(NSString *)elementName {
    id jsonObject = [self dictionaryOrArrayLoadedFromJSON:filePath];

    if (xpathQuery) {
        [[jsonObject pd_filterWithXPath:xpathQuery] pd_addElement:element withName:elementName];
    }

    else {
        [jsonObject pd_addElement:element withName:elementName];
    }

    return jsonObject;
}

+ (id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery removingElementNamed:(NSString *)elementName {
    id jsonObject = [self dictionaryOrArrayLoadedFromJSON:filePath];

    if (xpathQuery) {
        [[jsonObject pd_filterWithXPath:xpathQuery] pd_removeElementNamed:elementName];
    }

    else {
        [jsonObject pd_removeElementNamed:elementName];
    }

    return jsonObject;
}

+ (id)dictionaryOrArrayLoadedFromJSON:(NSString *)filePath {
    if (filePath == nil) {
        return nil;
    }

    NSData *data = [NSData dataWithContentsOfFile:filePath];

    return [NSMutableDictionary pd_dictionaryFromJSONData:data] ? : [NSArray pd_arrayFromJSONData:data];
}

@end
