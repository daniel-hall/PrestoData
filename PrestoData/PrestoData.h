//
// PrestoData.h
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
#import "NSArray+PrestoData.h"
#import "NSMutableDictionary+PrestoData.h"

extern NSString *const defaultInnerValueKey;

/** A class containing shortcut convenience methods for interacting with PrestoData */

@interface PrestoData : NSObject


/**---------------------------------------------------------------------------------------
* @name Modifying JSON Input
*  ---------------------------------------------------------------------------------------
*/


/** Returns a PrestoData dictionary or array created by loading a JSON file from the app bundle or document folder, filtering it with an XPath 1.0-style query, setting a new attribute value on all matching descendants, and returning the full modified dictionary or array
*
* Note: If the attribute already exists, its current value will be replaced by the new value.  If the attribute does not yet exist, it will be created with the new value.
*
* @param filePath An NSString representation of the path to JSON resource that will be loaded from the file system
* @param xpathQuery An NSString containing an XPath 1.0-style query to be applied to the JSON.  See documentation here:  http://www.w3schools.com/xpath/xpath_syntax.asp
* @param value A new NSString or NSNumber value that will be set for the attribute
* @param attributeName The name of the attribute to create or modify
* @return An NSMutableDictionary or NSArray (depending on what was modeled in the original JSON file) reflecting the changes made to the input JSON
*/
+(id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery withNewValue:(id)value forAttribute:(NSString *)attributeName;

/** Returns a PrestoData dictionary or array created by loading a JSON file from the app bundle or document folder, filtering it with an XPath 1.0-style query, removing the specified attribute from all matching descendants, and returning the full modified dictionary or array
* @param filePath An NSString representation of the path to JSON resource that will be loaded from the file system
* @param xpathQuery An NSString containing an XPath 1.0-style query to be applied to the JSON.  See documentation here:  http://www.w3schools.com/xpath/xpath_syntax.asp
* @param attributeName The name of the attribute to remove
* @return An NSMutableDictionary or NSArray (depending on what was modeled in the original JSON file) reflecting the changes made to the input JSON
*/
+(id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery removingAttributeNamed:(NSString *)attributeName;

/** Returns a PrestoData dictionary or array created by loading a JSON file from the app bundle or document folder, filtering it with an XPath 1.0-style query, adding the specified dictionary element to all matching descendants, and returning the full modified dictionary or array
*
* Note: If an element already exists with the specified name, the new element and the existing element will be combined into an array of elements
*
* @param filePath An NSString representation of the path to JSON resource that will be loaded from the file system
* @param xpathQuery An NSString containing an XPath 1.0-style query to be applied to the JSON.  See documentation here:  http://www.w3schools.com/xpath/xpath_syntax.asp
* @param element A PrestoDictionary dictionary that should be added as a child element to the matching descendants
* @param elementName The name that the new element will be mapped to
* @return An NSMutableDictionary or NSArray (depending on what was modeled in the original JSON file) reflecting the changes made to the input JSON
*/
+(id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery withNewElement:(NSMutableDictionary *)element named:(NSString *)elementName;

/** Returns a PrestoData dictionary or array created by loading a JSON file from the app bundle or document folder, filtering it with an XPath 1.0-style query, removing any element with the specified name from all matching descendants, and returning the full modified dictionary or array
* @param filePath An NSString representation of the path to JSON resource that will be loaded from the file system
* @param xpathQuery An NSString containing an XPath 1.0-style query to be applied to the JSON.  See documentation here:  http://www.w3schools.com/xpath/xpath_syntax.asp
* @param elementName The name of the element to remove from all matching descendants
* @return An NSMutableDictionary or NSArray (depending on what was modeled in the original JSON file) reflecting the changes made to the input JSON
*/
+(id)objectFromJSON:(NSString *)filePath filteredBy:(NSString *)xpathQuery removingElementNamed:(NSString *)elementName;

@end
