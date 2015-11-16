//
//  RHMQTT.h
//  RHSocketKitDemo
//
//  Created by zhuruhong on 15/11/11.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "RHPacketBody.h"
#import "RHPacketFrame.h"

//http://www.blogjava.net/yongboy/archive/2014/02/07/409587.html
//http://www.blogjava.net/yongboy/archive/2014/02/09/409630.html
//http://www.blogjava.net/yongboy/archive/2014/02/10/409689.html

typedef NS_ENUM(UInt8, RHMQTTMessageType) {
    RHMQTTMessageTypeConnect = 1,
    RHMQTTMessageTypeConnAck = 2,
    RHMQTTMessageTypePublish = 3,
    RHMQTTMessageTypePubAck = 4,
    RHMQTTMessageTypePubRec = 5,
    RHMQTTMessageTypePubRel = 6,
    RHMQTTMessageTypePubComp = 7,
    RHMQTTMessageTypeSubscribe = 8,
    RHMQTTMessageTypeSubAck = 9,
    RHMQTTMessageTypeUnsubscribe = 10,
    RHMQTTMessageTypeUnsubAck = 11,
    RHMQTTMessageTypePingReq = 12,
    RHMQTTMessageTypePingResp = 13,
    RHMQTTMessageTypeDisconnect = 14,
    RHMQTTMessageTypeReserved = 15
};

/** QoS(Quality of Service,服务质量) */
typedef NS_ENUM(UInt8, RHMQTTQosLevel) {
    RHMQTTQosLevelAtMostOnce = 0,               //至多一次，发完即丢弃，<=1
    RHMQTTQosLevelAtLeastOnce = 1,              //至少一次，需要确认回复，>=1
    RHMQTTQosLevelExactlyOnce = 2,              //只有一次，需要确认回复，＝1
    RHMQTTQosLevelReserved = 3                  //待用，保留位置
};

// ------------------------------------------

#pragma mark - NSData (MQTT)

@interface NSData (MQTT)

- (UInt8)valueFromByte;
- (UInt16)valueWithBytes;

@end

// ------------------------------------------

#pragma mark - NSMutableData (MQTT)

@interface NSMutableData (MQTT)

- (void)appendByte:(UInt8)byte;
- (void)appendUInt16BigEndian:(UInt16)val;
/** 这里有填充长度，需要控制字符串长度 */
- (void)appendMQTTString:(NSString*)string;

@end

// ------------------------------------------

#pragma mark - RHMQTTFixedHeader

/** Fixed header/固定头部 */
@interface RHMQTTFixedHeader : NSObject

@property (nonatomic, assign) RHMQTTMessageType type;       //4bit
@property (nonatomic, assign) BOOL dupFlag;                 //1bit
@property (nonatomic, assign) RHMQTTQosLevel qos;           //2bit
@property (nonatomic, assign) BOOL retainFlag;              //1bit

- (instancetype)initWithByte:(UInt8)byte;

@end

// ------------------------------------------

#pragma mark - RHMQTTVariableHeader

/** Variable header/可变头部 */
@interface RHMQTTVariableHeader : NSObject

/** protocol name */
@property (nonatomic, strong) NSString *name;

/** protocol version number, 1byte */
@property (nonatomic, assign) UInt8 version;

/** 
 * connect flags, 1byte
 *
 * user name flag:          1bit
 * password flag:           1bit
 * will retain:             1bit
 * will QoS:                2bit
 * will flag:               1bit
 * clean session:           1bit
 * reserved:                1bit
 */
@property (nonatomic, assign) UInt8 connectFlags;

/** keep alive timer, 2byte */
@property (nonatomic, assign) UInt16 keepAlive;

/** publish */
@property (nonatomic, strong) NSString *topic;

/** subscribe, publish */
@property (nonatomic, assign) UInt16 messageId;

@end

// ------------------------------------------

#pragma mark - RHMQTTPayload

@interface RHMQTTTopic : NSObject

/*
 * Will Topic
 *
 * Will Flag值为1，这里便是Will Topic的内容。
 * QoS级别通过Will QoS字段定义，RETAIN值通过Will RETAIN标识，都定义在可变头里面。
 */
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, assign) RHMQTTQosLevel qos;

@end

// ------------------------------------------

#pragma mark - RHMQTTPayload

/** Payload/消息体 */
@interface RHMQTTPayload : NSObject

/*
 * Client Identifier(客户端ID) 必填项。
 *
 * 1-23个字符长度，客户端到服务器的全局唯一标志
 * 如果客户端ID超出23个字符长度，服务器需要返回码为2，标识符被拒绝响应的CONNACK消息。
 *
 * 处理QoS级别1和2的消息ID中，可以使用到。
 */
@property (nonatomic, strong) NSString *clientId;

/** see RHMQTTTopic */
@property (nonatomic, strong) NSArray *topics;

/*
 * Will Message (长度有可能为0)
 *
 * Will Flag若设为1，这里便是Will Message定义消息的内容，对应的主题为Will Topic。
 * 如果客户端意外的断开触发服务器PUBLISH此消息。
 * 在CONNECT消息中的Will Message是UTF-8编码的，当被服务器发布时则作为二进制的消息体。
 */
@property (nonatomic, strong) NSData *message;

/** 如果设置User Name标识，可以在此读取用户名称。一般可用于身份验证。协议建议用户名为不多于12个字符，不是必须。*/
@property (nonatomic, strong) NSString *username;

/** 如果设置Password标识，便可读取用户密码。建议密码为12个字符或者更少，但不是必须。*/
@property (nonatomic, strong) NSString *password;

@end

// ------------------------------------------

#pragma mark - RHMQTTPacket

@interface RHMQTTPacket : RHPacketBody

@property (nonatomic, strong) RHMQTTFixedHeader *fixedHeader;
@property (nonatomic, strong) RHMQTTVariableHeader *variableHeader;
@property (nonatomic, strong) RHMQTTPayload *payload;

- (NSData *)dataWithFixedHeader;
- (NSData *)dataWithVariableHeader;
- (NSData *)dataWithPayload;

@end

// ------------------------------------------

#pragma mark - RHMQTTConnect

@interface RHMQTTConnect : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTPublish

@interface RHMQTTPublish : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTSubscribe

@interface RHMQTTSubscribe : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTUnsubscribe

@interface RHMQTTUnsubscribe : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTPingReq

@interface RHMQTTPingReq : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTDisconnect

@interface RHMQTTDisconnect : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTT

@interface RHMQTT : NSObject

+ (RHMQTTConnect *)connectWithClientId:(NSString *)clientId username:(NSString *)username password:(NSString *)password keepAlive:(UInt16)keepAlive cleanSession:(BOOL)cleanSession;
+ (RHMQTTSubscribe *)subscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic qos:(RHMQTTQosLevel)qos;
+ (RHMQTTUnsubscribe *)unsubscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic;

@end
