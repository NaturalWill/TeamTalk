//
//  TestTool.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/15.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import "TestTool.h"

@implementation TestTool

+ (NSData *)getRandomTestImageData {
    
    UIColor *color = [UIColor colorWithRed:[self randomIntWithLimit:255]/255.0 green:[self randomIntWithLimit:255]/255.0 blue:[self randomIntWithLimit:255]/255.0 alpha:1];
    CGFloat length = 100 + [self randomIntWithLimit:50];
    CGSize size = CGSizeMake(length, length);
    UIGraphicsBeginImageContext(size);
    [color set];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *pureColorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(pureColorImage);
}

+ (int)randomIntWithLimit:(int)limit {
    return (arc4random() % limit);
}

@end
