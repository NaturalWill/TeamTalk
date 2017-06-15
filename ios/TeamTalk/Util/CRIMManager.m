//
//  CRIMManager.m
//  TeamTalk
//
//  Created by ZHANG Zhipeng on 2017/6/14.
//  Copyright © 2017年 MoguIM. All rights reserved.
//

#import "CRIMManager.h"
#import "SendPushTokenAPI.h"
#import "PlayerManager.h"
#import "MTTDatabaseUtil.h"
#import "SessionModule.h"
#import "DDSendPhotoMessageAPI.h"
#import "NSDictionary+JSON.h"
#import <SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>

@implementation CRIMManager

#pragma mark - login methods
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

#pragma mark - send message methods
+ (void)sendMessage:(MTTMessageEntity *)message isGroup:(BOOL)isGroup Session:(MTTSessionEntity*)session completion:(DDSendMessageCompletion)completion Error:(void(^)(NSError *error))block {
    [[DDMessageSendManager instance] sendMessage:message isGroup:isGroup Session:session completion:^(MTTMessageEntity *message, NSError *error) {
        completion(message, error);
    } Error:^(NSError *error) {
        block(error);
    }];
}

+ (void)sendVoiceMessage:(NSData*)voice
                filePath:(NSString*)filePath
            forSessionID:(NSString*)sessionID
                 isGroup:(BOOL)isGroup
                 Message:(MTTMessageEntity *)msg
                 Session:(MTTSessionEntity*)session
         playingDelegate:(id<PlayingDelegate>)newDelegate
           DBSuceesBlock:(void(^)()) DBSuccess
          DBFailureBlock:(void(^)()) DBFailure {
    
    [[DDMessageSendManager instance] sendVoiceMessage:voice filePath:filePath forSessionID:sessionID isGroup:isGroup Message:msg Session:session completion:^(MTTMessageEntity *message, NSError *error) {
        if (!error)
        {
            DDLog(@"发送语音消息成功");
            [[PlayerManager sharedManager] playAudioWithFileName:@"msg.caf" playerType:DDSpeaker delegate:newDelegate];
            
            message.state = DDmessageSendSuccess;
            [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    DBSuccess();
                });
                
                
            }];
        } else {
            DDLog(@"发送语音消息失败");
            message.state = DDMessageSendFailure;
            [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    DBFailure();
                });
                
            }];
            
        }
        
    }];
}

+ (void)sendVoiceMessage:(NSData *)voice
                filePath:(NSString *)filePath
            forSessionID:(NSString *)sessionID
                 isGroup:(BOOL)isGroup
                 Message:(MTTMessageEntity *)msg
                 Session:(MTTSessionEntity *)session
              completion:(DDSendMessageCompletion)completion {
    [[DDMessageSendManager instance] sendVoiceMessage:voice filePath:filePath forSessionID:sessionID isGroup:isGroup Message:msg Session:session completion:^(MTTMessageEntity *message, NSError *error) {
        completion(message, error);
    }];
}

+ (void)sendImageMessage:(id)object Image:(UIImage *)image chatModule:(ChattingModule*)module makeMessageUIBlock:(void(^)())update successBlock:(void(^)(MTTMessageEntity *message))success failureBlock:(void(^)())failure
{
    NSString *localPath;
    MTTMessageEntity *message;
    bool shouldReSend = NO;
    if([object isKindOfClass:[MTTPhotoEnity class]]) {
        MTTPhotoEnity *photo = (MTTPhotoEnity *)object;
        NSDictionary* messageContentDic = @{DD_IMAGE_LOCAL_KEY:photo.localPath};
        NSString* messageContent = [messageContentDic jsonString];
        
        message = [MTTMessageEntity makeMessage:messageContent Module:module MsgType:DDMessageTypeImage];
        update();
        NSData *photoData = UIImagePNGRepresentation(image);
        [[MTTPhotosCache sharedPhotoCache] storePhoto:photoData forKey:photo.localPath toDisk:YES];
        [[MTTDatabaseUtil instance] insertMessages:@[message] success:^{
            DDLog(@"消息插入DB成功");
            
        } failure:^(NSString *errorDescripe) {
            DDLog(@"消息插入DB失败");
        }];
        photo=nil;
        localPath = messageContentDic[DD_IMAGE_LOCAL_KEY];
    } else if([object isKindOfClass:[MTTMessageEntity class]]) {
        message = (MTTMessageEntity *)object;
        NSDictionary* dic = [NSDictionary initWithJsonString:message.msgContent];
        localPath = dic[DD_IMAGE_LOCAL_KEY];
        __block UIImage* image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:localPath];
        if (!image)
        {
            NSData* data = [[MTTPhotosCache sharedPhotoCache] photoFromDiskCacheForKey:localPath];
            image = [[UIImage alloc] initWithData:data];
            if (!image) {
                update();
                return ;
            }
        }
        shouldReSend = YES;
    }
    
    [[DDSendPhotoMessageAPI sharedPhotoCache] uploadImage:localPath success:^(NSString *imageURL) {
        message.state=DDMessageSending;
        NSDictionary* tempMessageContent = [NSDictionary initWithJsonString:message.msgContent];
        NSMutableDictionary* mutalMessageContent = [[NSMutableDictionary alloc] initWithDictionary:tempMessageContent];
        [mutalMessageContent setValue:imageURL forKey:DD_IMAGE_URL_KEY];
        NSString* messageContent = [mutalMessageContent jsonString];
        message.msgContent = messageContent;
        success(message);
        if(!shouldReSend) {
            [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
            }];
        }
        
    } failure:^(id error) {
        message.state = DDMessageSendFailure;
        if([object isKindOfClass:[MTTPhotoEnity class]]) {
            //刷新DB
            [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                if (result)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure();
                    });
                }
            }];
        }
    }];
}


+ (void)reSendImageMessage:(id)object getImageFailureBlock:(void(^)())imageFailure successBlock:(void(^)())success failureBlock:(void(^)())failure {
    [CRIMManager sendImageMessage:object Image:nil chatModule:nil makeMessageUIBlock:^{
        imageFailure();
    } successBlock:^(MTTMessageEntity *message) {
        [[DDMessageSendManager instance] sendMessage:message isGroup:[message isGroupMessage] Session:[[SessionModule instance] getSessionById:message.sessionId] completion:^(MTTMessageEntity* theMessage,NSError *error) {
            if (error)
            {
                DDLog(@"发送消息失败");
                message.state = DDMessageSendFailure;
                //刷新DB
                [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                    if (result)
                    {
                        failure();
                    }
                }];
            }
            else
            {
                //刷新DB
                message.state = DDmessageSendSuccess;
                //刷新DB
                [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                    if (result)
                    {
                        success();
                    }
                }];
            }
        } Error:^(NSError *error) {
            DDLog(@"error: %@", error);
            [[MTTDatabaseUtil instance] updateMessageForMessage:message completion:^(BOOL result) {
                if (result)
                {
                    failure();
                }
            }];
        }];
        
    } failureBlock:^{
        failure();
    }];
}


@end
