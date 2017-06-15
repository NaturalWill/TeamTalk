//
//  CRIMManager.h
//  TeamTalk
//
//  Created by ZHANG Zhipeng on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginModule.h"
#import "DDMessageSendManager.h"
#import "PlayerManager.h"

@interface CRIMManager : NSObject

#pragma mark - login methods
+ (void)loginWithUserName:(NSString *)userName password:(NSString *)password success:(void(^)(bool suceess))success failure:(void(^)(NSString* error))failure;

+ (void)reloginSuccess:(void(^)())success failure:(void(^)(NSString* error))failure;


#pragma mark - send message methods
+ (void)sendMessage:(MTTMessageEntity *)message
            isGroup:(BOOL)isGroup
            Session:(MTTSessionEntity*)session
         completion:(DDSendMessageCompletion)completion
              Error:(void(^)(NSError *error))block;


+ (void)sendVoiceMessage:(NSData*)voice
                filePath:(NSString*)filePath
            forSessionID:(NSString*)sessionID
                 isGroup:(BOOL)isGroup
                 Message:(MTTMessageEntity *)msg
                 Session:(MTTSessionEntity*)session
         playingDelegate:(id<PlayingDelegate>)newDelegate
           DBSuceesBlock:(void(^)()) DBSuccess
          DBFailureBlock:(void(^)()) DBFailure;

+ (void)sendVoiceMessage:(NSData*)voice
                filePath:(NSString*)filePath
            forSessionID:(NSString*)sessionID
                 isGroup:(BOOL)isGroup
                 Message:(MTTMessageEntity *)msg
                 Session:(MTTSessionEntity*)session
              completion:(DDSendMessageCompletion)completion;



+ (void)sendImageMessage:(id)object Image:(UIImage *)image chatModule:(ChattingModule*)module makeMessageUIBlock:(void(^)())update successBlock:(void(^)(MTTMessageEntity *message))success failureBlock:(void(^)())failure;

+ (void)reSendImageMessage:(id)object getImageFailureBlock:(void (^)())imageFailure successBlock:(void(^)())success failureBlock:(void(^)())failure;


@end
