//
//  LoginTest.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/15.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "testConfig.h"
#import "DDHttpServer.h"
#import "DDTcpServer.h"
#import "DDClientState.h"
#import "DDClientStateMaintenanceManager.h"
#import "RuntimeStatus.h"
#import "LoginModule.h"

/**
 *  1.DDClientState只有userState和networkState是正确的
 *  2.登录结束后RuntimeStatus只有user属性是有值的
 *  3.LoginModule login方法未做异常输入处理,username或者password为nil程序会崩溃
 */

@interface LoginTest : XCTestCase
{
    DDHttpServer *_httpServer;
    DDTcpServer *_tcpServer;
    DDClientState *_clientState;
    LoginModule *_loginModule;
}
@end

@implementation LoginTest

- (void)setUp {
    [super setUp];
    
    [DDClientStateMaintenanceManager shareInstance];
    [RuntimeStatus instance];
    
    _httpServer = [[DDHttpServer alloc] init];
    _tcpServer = [[DDTcpServer alloc] init];
    _clientState = [DDClientState shareInstance];
    _loginModule = [LoginModule instance];
}

- (void)tearDown {
    _httpServer = nil;
    _tcpServer = nil;
    _clientState = nil;
    _loginModule = nil;
    
    [super tearDown];
}

- (void)testGetMsgIP {
    
    [_httpServer getMsgIp:^(NSDictionary *dic) {
        TEST_NOTIFY
        
        NSLog(@"%@", dic);
        XCTAssertNotNil(dic);
        XCTAssertEqual([dic[@"code"] integerValue], 0);
        XCTAssertNotNil(dic[@"priorIP"]);
        XCTAssertNotNil(dic[@"port"]);
        
    } failure:^(NSString *error) {
        TEST_NOTIFY
        XCTFail(@"获取消息服务器失败");
    }];
    
    TEST_WAIT
}

- (void)testConnectedTcpServer {
    [_httpServer getMsgIp:^(NSDictionary *dic) {
        
        NSInteger code = [[dic objectForKey:@"dic"] integerValue];
        NSString *priorIP = [dic objectForKey:@"priorIP"];
        NSInteger port = [[dic objectForKey:@"port"] integerValue];
        
        XCTAssertEqual(code, 0);
        XCTAssertNotNil(priorIP);
        XCTAssertNotEqual(0, port);
    
        
        [_tcpServer loginTcpServerIP:priorIP port:port Success:^{
            TEST_NOTIFY
            NSLog(@"----------------------------");
            NSLog(@"连接成功");
            NSLog(@"----------------------------");
        } failure:^{
            TEST_NOTIFY
            XCTFail(@"连接tcp服务器失败");
        }];
    } failure:^(NSString *error) {
        TEST_NOTIFY
        XCTFail(@"获取消息服务器失败");
    }];
    
    TEST_WAIT
}

- (void)testLogin {
    
    XCTAssertEqual(_clientState.userState, DDUserOffLine);
    
    [_loginModule loginWithUsername:@"liuaoming" password:@"123456" success:^(bool sucess) {
        TEST_NOTIFY
        XCTAssertEqual(_clientState.userState, DDUserOnline);

        RuntimeStatus *status = TheRuntime;
        XCTAssertNotNil(status.user);
        
    } failure:^(NSString *error) {
        TEST_NOTIFY
        XCTFail(@"登录失败");
    }];
    
    TEST_WAIT
}

- (void)testExceptionLogin {
    
    [_loginModule loginWithUsername:@"123456" password:nil success:^(bool sucess) {
        TEST_NOTIFY
        XCTAssertEqual(_clientState.userState, DDUserOffLine);
        XCTAssert(!sucess);
    } failure:^(NSString *error) {
        TEST_NOTIFY
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
