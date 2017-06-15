
//
//  DDMessageSendManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2015年 MoguIM All rights reserved.
//

#import "DDMessageSendManager.h"
#import "MTTUserEntity.h"
#import "MTTMessageEntity.h"
#import "MTTSessionEntity.h"
#import "SendMessageAPI.h"
#import "RuntimeStatus.h"
#import "EmotionsModule.h"
#import "NSDictionary+JSON.h"
#import "UnAckMessageManager.h"
#import "NSData+Conversion.h"
#import "MTTDatabaseUtil.h"
#import "security.h"
#import "DDSendPhotoMessageAPI.h"
#import <SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import "SessionModule.h"
static uint32_t seqNo = 0;

@interface DDMessageSendManager(PrivateAPI)

- (NSString* )toSendmessageContentFromContent:(NSString*)content;

@end

@implementation DDMessageSendManager
{
    NSUInteger _uploadImageCount;
}
+ (instancetype)instance
{
    static DDMessageSendManager* g_messageSendManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_messageSendManager = [[DDMessageSendManager alloc] init];
    });
    return g_messageSendManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _uploadImageCount = 0;
        _waitToSendMessage = [[NSMutableArray alloc] init];
        _sendMessageSendQueue = dispatch_queue_create("com.mogujie.Duoduo.sendMessageSend", NULL);
        
    }
    return self;
}

- (void)sendMessage:(MTTMessageEntity *)message isGroup:(BOOL)isGroup Session:(MTTSessionEntity*)session completion:(DDSendMessageCompletion)completion Error:(void (^)(NSError *))block
{
    
    dispatch_async(self.sendMessageSendQueue, ^{
        SendMessageAPI* sendMessageAPI = [[SendMessageAPI alloc] init];
        uint32_t nowSeqNo = ++seqNo;
        message.seqNo=nowSeqNo;
        
        NSString* newContent = message.msgContent;
        if ([message isImageMessage]) {
            NSDictionary* dic = [NSDictionary initWithJsonString:message.msgContent];
            NSString* urlPath = dic[DD_IMAGE_URL_KEY];
            newContent=urlPath;
        }
        
        char* pOut;
        uint32_t nOutLen;
        const char *test =[newContent cStringUsingEncoding:NSUTF8StringEncoding];
        uint32_t nInLen  = strlen(test);
        EncryptMsg(test, nInLen, &pOut, nOutLen);
        NSData *data = [[NSString stringWithCString:pOut encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
        Free(pOut);
        if(!message.msgID){
            return;
        }
        NSArray* object = @[TheRuntime.user.objID,session.sessionID,data,@(message.msgType),@(message.msgID)];
        if ([message isImageMessage]) {
            session.lastMsg=@"[图片]";
        }else if ([message isVoiceMessage])
        {
            session.lastMsg=@"[语言]";
        }else
        {
            session.lastMsg=message.msgContent;
        }
        [[UnAckMessageManager instance] addMessageToUnAckQueue:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
        [sendMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
            if (!error)
            {
                NSLog(@"发送消息成功");
                [[MTTDatabaseUtil instance] deleteMesages:message completion:^(BOOL success){
                    
                }];
                
                [[UnAckMessageManager instance] removeMessageFromUnAckQueue:message];
                //                    NSUInteger messageTime = [[NSDate date] timeIntervalSince1970];
                //                    message.msgTime=messageTime;
                message.msgID=[response[0] integerValue];
                message.state=DDmessageSendSuccess;
                session.lastMsgID=message.msgID;
                session.timeInterval=message.msgTime;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
                [[MTTDatabaseUtil instance] insertMessages:@[message] success:^{
                    
                } failure:^(NSString *errorDescripe) {
                    
                }];
                completion(message,nil);
                
                
            }
            else
            {
                message.state=DDMessageSendFailure;
                [[MTTDatabaseUtil instance] insertMessages:@[message] success:^{
                    
                } failure:^(NSString *errorDescripe) {
                    
                }];
                NSError* error = [NSError errorWithDomain:@"发送消息失败" code:0 userInfo:nil];
                block(error);
            }
        }];
        
    });
}

- (void)sendVoiceMessage:(NSData*)voice filePath:(NSString*)filePath forSessionID:(NSString*)sessionID isGroup:(BOOL)isGroup Message:(MTTMessageEntity *)msg Session:(MTTSessionEntity*)session completion:(DDSendMessageCompletion)completion
{
    dispatch_async(self.sendMessageSendQueue, ^{
        SendMessageAPI* sendVoiceMessageAPI = [[SendMessageAPI alloc] init];
        
        NSString* myUserID = [RuntimeStatus instance].user.objID;
        NSArray* object = @[myUserID,sessionID,voice,@(msg.msgType),@(0)];
        [sendVoiceMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
            if (!error)
            {
                
                
                NSLog(@"发送消息成功");
                [[MTTDatabaseUtil instance] deleteMesages:msg completion:^(BOOL success){
                    
                }];
                
                
                NSUInteger messageTime = [[NSDate date] timeIntervalSince1970];
                msg.msgTime=messageTime;
                msg.msgID=[response[0] integerValue];
                msg.state=DDmessageSendSuccess;
                session.lastMsg=@"[语音]";
                session.lastMsgID=msg.msgID;
                session.timeInterval=msg.msgTime;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
                [[MTTDatabaseUtil instance] insertMessages:@[msg] success:^{
                    
                } failure:^(NSString *errorDescripe) {
                    
                }];
                
                completion(msg,nil);
                
            }
            else
            {
                NSError* error = [NSError errorWithDomain:@"发送消息失败" code:0 userInfo:nil];
                completion(nil,error);
            }
        }];
        
    });
}

- (void)sendImageMessage:(id)object Image:(UIImage *)image chatModule:(ChattingModule*)module makeMessageUIBlock:(void(^)())update successBlock:(void(^)(MTTMessageEntity *message))success failureBlock:(void(^)())failure
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

- (void)reSendImageMessage:(id)object getImageFailureBlock:(void(^)())imageFailure successBlock:(void(^)())success failureBlock:(void(^)())failure {
    [self sendImageMessage:object Image:nil chatModule:nil makeMessageUIBlock:^{
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

#pragma mark Private API

- (NSString* )toSendmessageContentFromContent:(NSString*)content
{
    EmotionsModule* emotionModule = [EmotionsModule shareInstance];
    NSDictionary* unicodeDic = emotionModule.unicodeEmotionDic;
    NSArray* allEmotions = emotionModule.emotions;
    NSMutableString* newContent = [NSMutableString stringWithString:content];
    [allEmotions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* emotion = (NSString*)obj;
        if ([newContent rangeOfString:emotion].length > 0)
        {
            NSString* placeholder = unicodeDic[emotion];
            NSRange range = NSMakeRange(0, newContent.length);
            [newContent replaceOccurrencesOfString:emotion withString:placeholder options:0 range:range];
        }
    }];
    return newContent;
}


@end
