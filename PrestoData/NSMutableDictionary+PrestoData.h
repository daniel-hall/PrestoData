//
// NSMutableDictionary+PrestoData.h
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

/** A category containing all the methods used by Presto Data for searching, parsing, and modifying dictionaries */

@interface NSMutableDictionary (PrestoData)

/** Because keys and values in a normal NSDictionary have no guaranteed order, it is necessary to create a separate ordered array of keys to guarantee that elements can be converted to and from XML / JSON in the same order */
@property (nonatomic, readonly) NSArray *pd_orderedKeys;

/** The inner value exists in PrestoData dictionaries for compatibility with XML, which may contain a value inside the element directly, rather than as part of a named attribute or a sub-element.  Not needed when importing and exporting to JSON only.  Needed when importing from or exporting to XML that uses element inner values */
@property (nonatomic, readonly) id pd_innerValue;

/** The parent dictionary that this dictionary is an element of */
@property (nonatomic, weak, readonly) NSMutableDictionary *pd_parentDictionary;

/** The name of the element this dictionary is stored as */
@property (nonatomic, copy, readonly) NSString *pd_elementName;

/** A replacement for the default [NSObject description] property / method.  This property includes descriptions of values unique to PrestoData, like pd_innerValue and also prints the description of the elements in the correct order using the PrestoData orderedKeys property. */
@property (nonatomic, readonly) NSString *pd_description;


/** An equality checking method specifically to compare PrestoData dictionaries.  Use instead of the normal [NSObject isEqual:] method
*
* @param dictionary Another PrestoData dictionary
* @return YES if the dictionary has the same keys and values in the same order, as well as the same inner values; otherwise NO
*/
- (BOOL)pd_isEqualToDictionary:(NSMutableDictionary *)dictionary;

/** A copy method that produces deep copies specifically used to copy PrestoData dictionaries.  Use instead of the normal [NSObject copy] method
*
* @return A deep copy of this dictionary containing copies of its contents instead of pointers to the original contents
*/
- (instancetype)pd_copy;

/**---------------------------------------------------------------------------------------
* @name Creating a Dictionary from JSON or XML
*  ---------------------------------------------------------------------------------------
*/

/** Returns a PrestoData dictionary from UTF8-encoded JSON data using the default attribute name for inner values: "innerValue"
*
* @param jsonData An NSData instance that contains a UTF8-encoded JSON string
* @return An NSMutableDictionary instance if the JSON represents a dictionary and not an array, otherwise nil
*/
+ (instancetype)pd_dictionaryFromJSONData:(NSData *)jsonData;

/** Returns a PrestoData dictionary from UTF8-encoded JSON data using the specified attribute name for inner values.  In other words, if you will be converting JSON to XML later, and want a specific attribute to be used as the "inner value" of the XML element instead of an XML attribute, specify the name of that JSON attribute here.
*
* @param jsonData An NSData instance that contains a UTF8-encoded JSON string
* @param key The name of the JSON attribute which will signify that the value should be mapped to the inner value of each dictionary element in the resulting PrestoData dictionary, and in the event of conversion to XML.
* @return An NSMutableDictionary instance if the JSON represents a dictionary and not an array, otherwise nil
*/
+ (instancetype)pd_dictionaryFromJSONData:(NSData *)jsonData keyForInnerValue:(NSString *)key;

/** Returns a PrestoData dictionary from UTF8-encoded XML data
*
* @param xmlData An NSData instance that contains a UTF8-encoded XML string
* @return An NSMutableDictionary instance if the string contained valid XML, otherwise nil
*/
+ (instancetype)pd_dictionaryFromXMLData:(NSData *)xmlData;


/**---------------------------------------------------------------------------------------
* @name Changing Element Attributes
*  ---------------------------------------------------------------------------------------
*/


/** Sets the value for a specific key in this dictionary.  Returns the modified dictionary so methods can be chained.
*
* @param value The new value to store.  Valid types are NSString, NSNumber, NSMutableDictionary, or NSArray.
* @param attribute The name of the attribute the value will be set for.  If the attribute already exists, its current value will be overwritten.  If an attribute with this name does not already exist, it will be created.
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_setValue:(id)value forAttribute:(NSString *)attribute;

/** Deletes the specified attribute from the dictionary
*
* @param attribute The name of the attribute to delete
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_deleteAttribute:(NSString *)attribute;

/** Sets the inner value for this dictionary.  Returns the modified dictionary so methods can be chained.
*
* Inner values do not generally need to be used when parsing dictionaries into and out of JSON strings.  The inner value exists in PrestoData dictionaries for compatibility with XML, which may contain a value inside the element directly, rather than as part of a named attribute or a sub-element
*
* @param value The new value to store.  Valid types are NSString and NSNumber.
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_setInnerValue:(id)value;


/**---------------------------------------------------------------------------------------
* @name Adding and Removing Elements
*  ---------------------------------------------------------------------------------------
*/


/** Adds a child element to this dictionary, mapped to the specified element name
*
* Note: If an element is added with the same named as an existing element, then the element with this name will be converted to an array containing both the existing element and this new element.  If the element with this name is already an array, this element will be added to that array.
*
* @param element A mutable dictionary that will be added as a child element to this dictionary
* @param name The key that the child element will be mapped to inside this dictionary
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_addElement:(NSMutableDictionary *)element withName:(NSString *)name;

/** Removes an element with the specified name from the dictionary
*
* @param elementName The name of the element that should be removed
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_removeElementNamed:(NSString *)elementName;

/** Provides the same functionality as pd_removeElementNamed: but with an object reference instead of a name
*
* @param element A reference to the element that should be removed
* @return The modified dictionary that results from this operation
*/
- (instancetype)pd_removeElement:(NSMutableDictionary *)element;

/** Removes this dictionary from the dictionary it is a child element of */
- (void)pd_removeFromParentDictionary;


/**---------------------------------------------------------------------------------------
* @name Filtering Elements
*  ---------------------------------------------------------------------------------------
*/


/** Returns an array of all child or descendant elements inside this dictionary which match the specified XPath query
*
* @param xPathString A string containing an XPath 1.0-style query.  See documentation here:  http://www.w3schools.com/xpath/xpath_syntax.asp
* @return The array of matching elements
*/
- (NSArray *)pd_filterWithXPath:(NSString *)xPathString;

/** Returns all child and descendant elements inside this dictionary which have the specified name.  Primarily used in XPath operations
*
* @param name The element name to search this dictionary and its child elements for
* @return The array of matching descendants
*/
- (NSArray *)pd_descendantsNamed:(NSString *)name;

/** Returns all child elements inside this dictionary which have the specified name.  Primarily used in XPath operations
*
* @param name The element name to search this dictionary for
* @return The array of matching children
*/
- (NSArray *)pd_childrenNamed:(NSString *)name;


/**---------------------------------------------------------------------------------------
* @name Converting to JSON and XML
*  ---------------------------------------------------------------------------------------
*/

/** Returns a JSON string representation of this dictionary, using the default key name that will be used for any inner values
*
* @return A JSON string representation of this dictionary
*/
- (NSString *)pd_jsonString;

/** Returns a JSON string representation of this dictionary, using the specified key name that will be used for any inner values
*
* @param keyForInnerValue The key name that will be used to map any inner values to JSON attributes.
* @return A JSON string representation of this dictionary
*/
- (NSString *)pd_jsonStringWithInnerValueKey:(NSString *)keyForInnerValue;

/** Returns an XML string representation of this dictionary
*
* @return An XML string representation of this dictionary
*/
- (NSString *)pd_xmlString;

@end
