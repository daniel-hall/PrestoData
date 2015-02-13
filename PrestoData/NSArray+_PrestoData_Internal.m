//
// NSArray+_PrestoData_Internal.m
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

#import "NSArray+_PrestoData_Internal.h"
#import "NSMutableDictionary+_PrestoData_Internal.h"
#import "NSMutableDictionary+PrestoData.h"
#import <objc/runtime.h>

@implementation NSArray (_PrestoData_Internal)


- (NSMutableDictionary *)pd_parentDictionary
{
    return objc_getAssociatedObject(self, @selector(pd_parentDictionary));
}


- (void)setPd_parentDictionary:(NSDictionary *)value
{
    objc_setAssociatedObject(self, @selector(pd_parentDictionary), value, OBJC_ASSOCIATION_ASSIGN);
}

- (NSString *)pd_elementName
{
    return objc_getAssociatedObject(self, @selector(pd_elementName));
}


- (void)setPd_elementName:(NSString *)value
{
    objc_setAssociatedObject(self, @selector(pd_elementName), value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end
