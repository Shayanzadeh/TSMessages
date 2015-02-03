//
//  UIColor+HexString.m
//  Prototype
//
//  Created by Shayan Yousefizadeh on 10/06/2014.
//  Copyright (c) 2014 Trinity College Dublin. All rights reserved.
//

#import "UIColor+HexString.h"

@implementation UIColor (HexString)

+ (instancetype)colorWithHexString:(NSString *)hexString
{
    unsigned int hexValue;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // skip '#' character
    [scanner scanHexInt:&hexValue];
    
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                           green:((float)((hexValue & 0xFF00) >> 8))/255.0
                            blue:((float)(hexValue & 0xFF))/255.0
                           alpha:1.0];
}

@end
