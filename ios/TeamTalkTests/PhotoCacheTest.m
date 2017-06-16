//
//  PhotoCache.m
//  TeamTalk
//
//  Created by Lamb on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTTPhotosCache.h"
#import "testConfig.h"

@interface PhotoCacheTest : XCTestCase

@property (nonatomic, strong) MTTPhotosCache *photoCache;

@property (nonatomic, strong) NSData *testPhontData;
@property (nonatomic, strong) NSData *testPhontData2;

@end

/**
 *  测试结果
 *  有几个方法有是异步方法却没有提供回调
 *  例如在写入缓存之后马上查询缓存大小结果与实际不同
 */

@implementation PhotoCacheTest

- (void)setUp {
    [super setUp];
    
    MTTPhotosCache *photoCache1 = [MTTPhotosCache sharedPhotoCache];
    MTTPhotosCache *photoCache2 = [MTTPhotosCache sharedPhotoCache];
    self.photoCache = photoCache2;
    XCTAssertEqual(photoCache1, photoCache2);
}

- (void)tearDown {
    [self.photoCache clearAllCache:^(bool isfinish) {
        self.photoCache = nil;
    }];
    [super tearDown];
}

- (void)testInput {
    
    [self.photoCache storePhoto:nil forKey:nil toDisk:nil];
    NSData *data = [self.photoCache photoFromDiskCacheForKey:nil];
    
    NSOperation *operation = [self.photoCache queryDiskCacheForKey:nil done:nil];
    
    XCTAssertNil(data);
    XCTAssertNil(operation);
    
}

- (void)testClearAllCache {
    
    [self.photoCache clearAllCache:^(bool isfinish) {
        // calculatePhotoSizeWithCompletionBlock
        [MTTPhotosCache calculatePhotoSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
            TEST_NOTIFY
            
            NSLog(@"----------------------------------------");
            NSLog(@"%ld files, %ld size", (unsigned long)fileCount, totalSize);
            NSLog(@"----------------------------------------");
            XCTAssertEqual(fileCount, 0);
            XCTAssertEqual(totalSize, 0);
        }];
    }];

    TEST_WAIT
}

- (void)testStorePhoto {
    
    int count = 2000;
    
    // 清除所有缓存
    [self.photoCache clearAllCache:^(bool isfinish) {
        
        NSInteger size = [self.photoCache getSize];
        XCTAssertEqual(size, 0);
        
        // 存入模拟数据
        for (int i = 0; i < count; i++) {
            [self.photoCache storePhoto:self.testPhontData forKey:[NSString stringWithFormat:@"testPhotoData%d",i] toDisk:YES];
        }
        // 计算缓存大小
        
//        sleep(5);
        
        [MTTPhotosCache calculatePhotoSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
            TEST_NOTIFY
            
            XCTAssertEqual(fileCount, count);
            XCTAssertEqual(totalSize, count * self.testPhontData.length);
        }];
    }];

    
    TEST_WAIT
}

- (void)testGetCachePhoto {
    
    NSString *key = @"testGetCachePhoto";
    
    [self.photoCache storePhoto:self.testPhontData forKey:key toDisk:YES];
    sleep(1);
    NSData *newPhotoData = [self.photoCache photoFromDiskCacheForKey:key];
//    NSString *path = [self.photoCache getKeyName];
//    NSLog(@"%@", path);
    XCTAssertEqualObjects(newPhotoData, self.testPhontData);
    XCTAssertNotEqualObjects(newPhotoData, self.testPhontData2);
    
    [self.photoCache removePhotoForKey:key];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    int testCount = 300;
    [self measureBlock:^{
        for (int i = 0; i < testCount; i++) {
            NSString *key = [NSString stringWithFormat:@"testPhontData%d", i];
            [self.photoCache storePhoto:self.testPhontData forKey:key toDisk:YES];
        }
    }];
    
    sleep(5);
}

#pragma mark - lazy load
- (NSData *)testPhontData {
    if (!_testPhontData) {
        _testPhontData = [TestTool getRandomTestImageData];
    }
    return _testPhontData;
}
- (NSData *)testPhontData2 {
    if (!_testPhontData2) {
        _testPhontData2 = [TestTool getRandomTestImageData];
    }
    return _testPhontData2;
}

@end
