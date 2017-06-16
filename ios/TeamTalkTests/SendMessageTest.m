//
//  SendMessageTest.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/16.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestConfig.h"
#import "DDMessageSendManager.h"

@interface SendMessageTest : XCTestCase

@end

@implementation SendMessageTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    
//    [[DDMessageSendManager instance] sendMessage:<#(MTTMessageEntity *)#> isGroup:<#(BOOL)#> Session:<#(MTTSessionEntity *)#> completion:<#^(MTTMessageEntity *message, NSError *error)completion#> Error:<#^(NSError *error)block#>]
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
