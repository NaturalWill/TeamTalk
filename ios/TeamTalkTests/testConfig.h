//
//  testConfig.h
//  TeamTalk
//
//  Created by Lamb on 2017/6/15.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#ifndef testConfig_h
#define testConfig_h

/// 头文件

#import "TestTool.h"

/// 异步方法测试宏定义
#define TEST_NOTIFY_KEY (@"nim_test_notification")

#define TEST_NOTIFY_WITH_KEY(key)\
{\
dispatch_async(dispatch_get_main_queue(), ^{ \
[[NSNotificationCenter defaultCenter] postNotificationName:(key) object:nil];\
});\
}

#define TEST_WAIT_WITH_KEY(key)\
{\
[self expectationForNotification:(key) object:nil handler:nil];\
[self waitForExpectationsWithTimeout:60 handler:nil];\
}

#define TEST_WAIT       TEST_WAIT_WITH_KEY(TEST_NOTIFY_KEY)
#define TEST_NOTIFY     TEST_NOTIFY_WITH_KEY(TEST_NOTIFY_KEY)

#endif /* testConfig_h */
