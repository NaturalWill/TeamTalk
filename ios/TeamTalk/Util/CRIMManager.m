//
//  CRIMManager.m
//  TeamTalk
//
//  Created by ZHANG Zhipeng on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import "CRIMManager.h"
#import "SendPushTokenAPI.h"

@implementation CRIMManager
/*
+ (id)sharedManager {
    static CRIMManager *_shareManager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _shareManager = [[self alloc] init];
    });
    
    return _shareManager;
}

- (id)init {
    if (self == [super init]) {
        self.loginModule = [LoginModule instance];
    }
    
    return self;
}
*/

/// Login methods
+ (void)loginWithUserName:(NSString *)userName password:(NSString *)password success:(void(^)   (bool success))success failure:(void(^)(NSString* error))failure {
    [[LoginModule instance] loginWithUsername:userName password:password success:^(bool sucess) {
        [TheRuntime updateData];
        
        if (TheRuntime.pushToken) {
            SendPushTokenAPI *pushToken = [[SendPushTokenAPI alloc] init];
            [pushToken requestWithObject:TheRuntime.pushToken Completion:^(id response, NSError *error) {
                
            }];
        }

        success(sucess);
    } failure:^(NSString *error) {
        failure(error);
    }];
}

+ (void)reloginSuccess:(void (^)())success failure:(void (^)(NSString *))failure {
    [[LoginModule instance] reloginSuccess:^{
        success();
    } failure:^(NSString *error) {
        failure(error);
    }];
}

/// Send Message methods
+ (void)sendMessage:(MTTMessageEntity *)message isGroup:(BOOL)isGroup Session:(MTTSessionEntity*)session completion:(DDSendMessageCompletion)completion Error:(void(^)(NSError *error))block {
    [CRIMManager sendMessage:message isGroup:isGroup Session:session completion:^(MTTMessageEntity *message, NSError *error) {
        completion(message, error);
    } Error:^(NSError *error) {
        block(error);
    }];
}

+ (void)sendVoiceMessage:(NSData*)voice filePath:(NSString*)filePath forSessionID:(NSString*)sessionID isGroup:(BOOL)isGroup Message:(MTTMessageEntity *)msg Session:(MTTSessionEntity*)session completion:(DDSendMessageCompletion)completion {
    [[DDMessageSendManager instance] sendVoiceMessage:voice filePath:filePath forSessionID:sessionID isGroup:isGroup Message:msg Session:session completion:^(MTTMessageEntity *message, NSError *error) {
        completion(message, error);
    }];
}

+ (void)sendImageMessage:(id)object Image:(UIImage *)image chatModule:(ChattingModule *)module makeMessageUIBlock:(void (^)())update successBlock:(void (^)(MTTMessageEntity *message))success failureBlock:(void (^)())failure {
    [[DDMessageSendManager instance] sendImageMessage:object Image:image chatModule:module makeMessageUIBlock:^{
        update();
    } successBlock:^(MTTMessageEntity *message) {
        success(message);
    } failureBlock:^{
        failure();
    }];
}

+ (void)reSendImageMessage:(id)object getImageFailureBlock:(void (^)())imageFailure successBlock:(void (^)())success failureBlock:(void (^)())failure {
    [[DDMessageSendManager instance] reSendImageMessage:object getImageFailureBlock:^{
        imageFailure();
    } successBlock:^{
        success();
    } failureBlock:^{
        failure();
    }];
}


@end
