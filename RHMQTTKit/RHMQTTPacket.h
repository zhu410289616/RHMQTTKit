//
//  RHMQTTPacket.h
//  Pods
//
//  Created by ruhong zhu on 2021/8/21.
//

#import <Foundation/Foundation.h>
#import <RHSocketKit/RHSocketKit.h>

//http://www.blogjava.net/yongboy/archive/2014/02/07/409587.html
//http://www.blogjava.net/yongboy/archive/2014/02/09/409630.html
//http://www.blogjava.net/yongboy/archive/2014/02/10/409689.html

/** message type */
typedef NS_ENUM(UInt8, RHMQTTMessageType) {
    RHMQTTMessageTypeConnect = 1,           //client request to connect to server
    RHMQTTMessageTypeConnAck = 2,           //connect acknowledgment
    RHMQTTMessageTypePublish = 3,           //publish message
    RHMQTTMessageTypePubAck = 4,            //publish acknowledgment
    RHMQTTMessageTypePubRec = 5,            //publish received (assured delivery part 1)
    RHMQTTMessageTypePubRel = 6,            //publish release (assured delivery part 2)
    RHMQTTMessageTypePubComp = 7,           //publish complete (assured delivery part 3)
    RHMQTTMessageTypeSubscribe = 8,         //client subscribe request
    RHMQTTMessageTypeSubAck = 9,            //subscribe acknowledgment
    RHMQTTMessageTypeUnsubscribe = 10,      //client unsubscribe request
    RHMQTTMessageTypeUnsubAck = 11,         //unsubscribe acknowledgment
    RHMQTTMessageTypePingReq = 12,          //ping request
    RHMQTTMessageTypePingResp = 13,         //ping response
    RHMQTTMessageTypeDisconnect = 14,       //client is disconnecting
    RHMQTTMessageTypeReserved = 15          //reserved
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
@interface RHMQTTVariableHeader : NSObject <RHSocketPacket>

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

@interface RHMQTTPacket : RHSocketPacketRequest

/** 剩余长度 remainingLength 的二进制数据（1-4个字节，可变） */
@property (nonatomic, strong) NSData *remainingLengthData;
/** 剩余长度 = 可变头部内容字节长度 + Playload/负荷字节长度 */
@property (nonatomic, assign) NSInteger remainingLength;

/** 1 个字节 */
@property (nonatomic, strong) RHMQTTFixedHeader *fixedHeader;
@property (nonatomic, strong) RHMQTTVariableHeader *variableHeader;
@property (nonatomic, strong) RHMQTTPayload *payload;

- (NSData *)dataWithFixedHeader;
- (NSData *)dataWithVariableHeader;
- (NSData *)dataWithPayload;
- (NSData *)data;

@end

// ------------------------------------------

#pragma mark - RHMQTTConnect

@interface RHMQTTConnect : RHMQTTPacket

+ (RHMQTTConnect *)connectWithClientId:(NSString *)clientId username:(NSString *)username password:(NSString *)password keepAlive:(UInt16)keepAlive cleanSession:(BOOL)cleanSession;

@end

// ------------------------------------------

#pragma mark - RHMQTTPublish

@interface RHMQTTPublish : RHMQTTPacket

@end

#pragma mark - RHMQTTPublishAck

@interface RHMQTTPublishAck : RHMQTTPacket

- (instancetype)initWithMessageId:(int16_t)msgId;

@end

#pragma mark - RHMQTTPublishRec

@interface RHMQTTPublishRec : RHMQTTPacket

- (instancetype)initWithMessageId:(int16_t)msgId;

@end

#pragma mark - RHMQTTPublishRel

@interface RHMQTTPublishRel : RHMQTTPacket

- (instancetype)initWithMessageId:(int16_t)msgId;

@end

#pragma mark - RHMQTTPublishComp

/**
 作为QoS level = 2消息流第四个，也是最后一个消息，由收到PUBREL的一方向另一方做出的响应消息。
 完整的消息一览，和PUBREL一致，除了消息类型。
 */
@interface RHMQTTPublishComp : RHMQTTPacket

- (instancetype)initWithMessageId:(int16_t)msgId;

@end

// ------------------------------------------

#pragma mark - RHMQTTSubscribe

@interface RHMQTTSubscribe : RHMQTTPacket

+ (RHMQTTSubscribe *)subscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic qos:(RHMQTTQosLevel)qos;

@end

// ------------------------------------------

#pragma mark - RHMQTTUnsubscribe

@interface RHMQTTUnsubscribe : RHMQTTPacket

+ (RHMQTTUnsubscribe *)unsubscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic;

@end

// ------------------------------------------

#pragma mark - RHMQTTPingReq

@interface RHMQTTPingReq : RHMQTTPacket

@end

// ------------------------------------------

#pragma mark - RHMQTTDisconnect

@interface RHMQTTDisconnect : RHMQTTPacket

@end
