//
// NSString+_PrestoData_Internal.h
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

/** This category is used internally by PrestoData for parsing JSON and XML values out of strings, and processing XPath queries */

@interface NSString (_PrestoData_Internal)

/** Checks whether the current string matches the specified string with single character (?) or multiple character (*) wildcard symbols
* @return YES if a match, otherwise NO
*/
- (BOOL)pd_matchesWildcardedString:(NSString *)string;


/**---------------------------------------------------------------------------------------
* @name XPath Query Parsing
*  ---------------------------------------------------------------------------------------
*/


/** Extracts and returns the first XPath grouping (inside parentheses) from an XPath query string.
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the first grouping is extracted
* @return The contents of the first XPath grouping
*/
- (NSString *)pd_extractInitialGroupingWithRemainder:(NSString **)remainingString;

/** Extracts and returns the first specified descendant name from an XPath query).
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the first descendant is extracted
* @return The name of the first Xpath descendant specified in an XPath query string
*/
- (NSString *)pd_extractFirstXPathDescendantWithRemainder:(NSString **)remainingString;

/** Extracts and returns the first specified child name from an XPath query).
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the first child is extracted
* @return The name of the first XPath child specified in an XPath query string
*/
- (NSString *)pd_extractFirstXPathChildWithRemainder:(NSString **)remainingString;

/** Extracts and returns the predicate from an XPath query).
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the predicate is extracted
* @return The XPath predicate specified in an XPath query string
*/
- (NSString *)pd_extractXPathPredicateWithRemainder:(NSString **)remainingString;

/** Checks whether the string is an XPath predicate that matches a specific attribute.
* @return YES if the string is an XPath attribute predicate, otherwise NO
*/
- (BOOL)pd_isXPathAttributePredicate;

/** Checks whether the string is an XPath predicate that compares attribute values.
* @return YES if the string is an XPath comparison predicate, otherwise NO
*/
- (BOOL)pd_isXPathComparisonPredicate;

/** Checks whether the string is an XPath predicate that checks the index of an element in an array.
* @return YES if the string is an XPath position predicate, otherwise NO
*/
- (BOOL)pd_isXPathPositionPredicate;

/** Find the location of a comparison operator inside an XPath query predicate string
* @return The index of the operator
*/
- (NSUInteger)pd_indexOfOperatorInXPathPredicate;

/** Extracts the attribute name specified in an XPath attribute predicate string
* @return The name of the attribute
*/
- (NSString *)pd_attributeFromXPathPredicate;

/** Extracts the element being compared to a value in an XPath comparison predicate string
* @return The name of the element
*/
- (NSString *)pd_elementFromXPathPredicate;

/** Extracts the string containing the comparison from an XPath comparison predicate
* @return The string representing the comparison
*/
- (NSString *)pd_comparisonStringFromXPathPredicate;

/** Create an XPath comparison predicate by substituting the position() function with a specific index
* @param index The index that the element's own index should be compared with
* @return An XPath comparison predicate string
*/
- (NSString *)pd_positionComparisonStringFromXPathPredicateUsingIndex:(NSUInteger)index;

/** Checks whether an XPath comparison predicate is comparing numeric values
* @return YES if numeric comparison, otherwise NO
*/
- (BOOL)pd_isXPathPredicateNumericExpression;

/** Create an NSExpression from the XPath numeric comparison predicate
* @return An NSExpression created from the XPath numeric comparison predicate
*/
- (NSExpression *)pd_xpathPredicateNumericExpression;

/** Trims the XPath predicate brackets [] from an XPath predicate string
* @return The trimmed string
*/
- (NSString *)pd_stringByTrimmingXPathPredicateString;

/** Extracts and returns the next key name from a JSON string
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the next JSON key name is extracted
* @return The name of the next key in a JSON string
*/


/**---------------------------------------------------------------------------------------
* @name JSON Parsing
*  ---------------------------------------------------------------------------------------
*/


- (NSString *)pd_extractNextJSONKeyWithRemainder:(NSString **)remainingString;

/** Extracts and returns the next value from a JSON string
* @param remainingString A pointer to an NSString pointer which should reference the remaining string after the next JSON value is extracted
* @return The name of the next value in a JSON string
*/
- (NSString *)pd_extractNextJSONValueStringWithRemainder:(NSString **)remainingString;

/** Checks whether the string represents a JSON object / dictionary value
* @return YES if the string is a JSON object / dictionary, otherwise NO
*/
- (BOOL)pd_isJSONDictionaryValue;

/** Checks whether the string represents a JSON array value
* @return YES if the string is a JSON array, otherwise NO
*/
- (BOOL)pd_isJSONArrayValue;

/** Checks whether the string represents a JSON string value
* @return YES if the string is a JSON string value, otherwise NO
*/
- (BOOL)pd_isJSONStringValue;

/** Checks whether the string represents a JSON number value
* @return YES if the string is a JSON number value, otherwise NO
*/
- (BOOL)pd_isJSONNumberValue;

/** Extracts and returns a dictionary from a JSON string
* @return An NSMutableDictionary that represents the object in the JSON string
*/
- (NSMutableDictionary *)pd_extractJSONDictionaryValue;

/** Extracts and returns an array from a JSON string
* @return An NSArray that represents the array in the JSON string
*/
- (NSArray *)pd_extractJSONArrayValue;

/** Extracts and returns a string from a JSON string
* @return An NSString that represents the JSON string value
*/
- (NSString *)pd_extractJSONStringValue;

/** Extracts and returns a number from a JSON string
* @return An NSNumber that represents the JSON number value
*/
- (NSNumber *)pd_extractJSONNumberValue;

@end
