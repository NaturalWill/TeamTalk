//
//  MTTUtilTest.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTTUtil.h"

@interface MTTUtilTest : XCTestCase

@end

@implementation MTTUtilTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetFirstChar {
    
    NSString *ceshi = @"测试";
    char ceshiFirstChar = [MTTUtil getFirstChar:ceshi];
    XCTAssertEqual(ceshiFirstChar, 'c');
    
    NSString *liu = @"刘";
    char liuFirstChar = [MTTUtil getFirstChar:liu];
    XCTAssertEqual(liuFirstChar, 'l');
    
    NSString *one = @"2";
    char oneFirstChar = [MTTUtil getFirstChar:one];
    XCTAssertEqual(oneFirstChar, '2');
    
    NSString *qingtian = @"qingtian";
    char qingtianFirstChar = [MTTUtil getFirstChar:qingtian];
    XCTAssertEqual(qingtianFirstChar, 'q');
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
