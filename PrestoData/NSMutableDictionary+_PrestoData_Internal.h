//
// NSMutableDictionary+_PrestoData_Internal.h
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


#import <Foundation/Foundation.h>

/** This category is used internally by PrestoData for keeping track of the element name and parent reference for a dictionary element */

@interface NSMutableDictionary (_PrestoData_Internal)

/** The inner value exists in PrestoData dictionaries for compatibility with XML, which may contain a value inside the element directly, rather than as part of a named attribute or a sub-element.  Not needed when importing and exporting to JSON only.  Needed when importing from or exporting to XML that uses element inner values */
@property (nonatomic, strong) id pd_innerValue;

/** The parent dictionary that this dictionary is an element of */
@property (nonatomic, weak) NSMutableDictionary *pd_parentDictionary;

/** The name of the element this dictionary is stored as */
@property (nonatomic, copy) NSString *pd_elementName;

/** Transfers attribute values with the specified key name to the NSMutableDictionary.pd_innerValue property ]
* @param key The name of the key for this dictionary and any child dictionaries whose value should be copied over to the pd_innerValue property and then removed as an attribute
* */
- (void)pd_setParsedDictionaryPropertiesWithInnerValueKey:(NSString *)key;

@end
