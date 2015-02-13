//
// PrestoDataXPathTests.m
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


#import <XCTest/XCTest.h>
#import "NSMutableDictionary+PrestoData.h"
#import "NSMutableDictionary+_PrestoData_Internal.h"
#import "NSArray+PrestoData.h"

@interface PrestoDataXPathTests : XCTestCase

@property (nonatomic, readonly) NSMutableDictionary* dictionary;

@end

@implementation PrestoDataXPathTests

- (void)testUngroupedIndex
{
    NSMutableDictionary *firstExpected = [NSMutableDictionary dictionary];
    [firstExpected pd_setInnerValue:@"Vaidyanathan Nagarajan"];
    firstExpected.pd_elementName = @"author";
    NSMutableDictionary *secondExpected = [NSMutableDictionary dictionary];
    [secondExpected pd_setInnerValue:@"Erik T. Ray"];
    secondExpected.pd_elementName = @"author";
    NSArray *expectedResults = @[firstExpected, secondExpected];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[year < 2005]/author[last()]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testGroupedIndex
{
    NSMutableDictionary *firstExpected = [NSMutableDictionary dictionary];
    [firstExpected pd_setInnerValue:@"Erik T. Ray"];
    firstExpected.pd_elementName = @"author";
    NSArray *expectedResults = @[firstExpected];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"(/bookstore/book[year < 2005]/author)[last()]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testChildValueComparison
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testChildValueComparisonExpectedResults" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = expectedDictionary[@"test"][@"book"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[price>35.00]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}


- (void)testChildValueComparisonChildren
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testChildValueComparisonChildren" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = expectedDictionary[@"test"][@"title"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[price>35.00]/title"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testIndexPredicate
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testIndexPredicate" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = @[expectedDictionary[@"book"]];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[1]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testLastPredicate
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testLastPredicate" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = @[expectedDictionary[@"book"]];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[last()]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testLastMinusOnePredicate
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testLastMinusOnePredicate" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = @[expectedDictionary[@"book"]];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[last() - 1]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testPositionPredicate
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testPositionPredicate" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = expectedDictionary[@"test"][@"book"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"/bookstore/book[position()<=3]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testAttributeComparison
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testAttributeComparison" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = expectedDictionary[@"test"][@"title"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"//title[@lang='en']"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (void)testAttributeExistence
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testAttributeExistence" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = expectedDictionary[@"test"][@"title"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"//title[@lang]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

-(void)testWildcardElement
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testWildcardElement" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = [expectedDictionary[@"test"] pd_childrenNamed:@"*"];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"//book[@category = 'CHILDREN']/*"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

-(void)testWildcardAttributeExistence
{
    NSString *xmlPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testWildcardAttributeExistence" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    NSMutableDictionary *expectedDictionary = [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];
    NSArray *expectedResults = @[expectedDictionary[@"test"][@"title"]];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"//book[@category = 'CHILDREN']/*[@*]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

-(void)testNarrowWildcardAttributeExistence
{
    NSMutableDictionary *firstExpected = [NSMutableDictionary dictionary];
    [firstExpected pd_setInnerValue:@"Harry Potter"];
    [firstExpected pd_setValue:@"fr" forAttribute:@"lang"];
    firstExpected.pd_elementName = @"title";
    NSArray *expectedResults = @[firstExpected];
    NSArray *results = [self.dictionary pd_filterWithXPath:@"//book[@category = 'CHILDREN']/*[@*g]"];
    XCTAssert([results pd_isEqualToArray:expectedResults], @"didn't get expected results");
}

- (NSMutableDictionary *)dictionary
{
    NSString *xmlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
    return [NSMutableDictionary pd_dictionaryFromXMLData:xmlData];

    
}


@end
