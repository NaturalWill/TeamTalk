//
//  Search.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DDSearch.h"
#import "LoginModule.h"
#import "testConfig.h"

@interface SearchTest : XCTestCase
@property (nonatomic, strong) DDSearch *search;
@property (nonatomic, strong) LoginModule *loginMoudle;
@end

@implementation SearchTest

- (void)setUp {
    [super setUp];
    
    self.loginMoudle = [LoginModule instance];
    
    self.search = [DDSearch instance];
}

- (void)tearDown {
    self.search = nil;
    [super tearDown];
}

- (void)testExample {
    
    [self.loginMoudle loginWithUsername:@"liuaoming" password:@"123456" success:^(bool sucess) {
//        [self.search searchContent:@"1" completion:^(NSArray *result, NSError *error) {
//            NSLog(@"----------------------------------------");
//            NSLog(@"%@", result);
//            NSLog(@"----------------------------------------");
//
//        }];
        
        [self.search searchDepartment:@"1" completion:^(NSArray *result, NSError *error) {
            NSLog(@"----------------------------------------");
            NSLog(@"%@", result);
            NSLog(@"----------------------------------------");
            
            TEST_NOTIFY
        }];
    } failure:^(NSString *error) {
        
    }];
    
    
    
    TEST_WAIT
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
