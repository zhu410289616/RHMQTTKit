//
//  RHMQTT.m
//  RHSocketKitDemo
//
//  Created by zhuruhong on 15/11/11.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "RHMQTT.h"

// ------------------------------------------

#pragma mark - NSData (MQTT)

@implementation NSData (MQTT)

- (UInt8)valueFromByte
{
    UInt8 value = 0;
    [self getBytes:&value length:1];
    return value;
}

- (UInt16)valueWithBytes
{
    UInt16 messageIdL = 0;
    UInt16 messageIdH = 0;
    [self getBytes:&messageIdH range:NSMakeRange(0, 1)];
    [self getBytes:&messageIdL range:NSMakeRange(1, 1)];
    UInt16 msgId = messageIdL | messageIdH << 8;
    return msgId;
}

@end

// ------------------------------------------

#pragma mark - NSMutableData (MQTT)

@implementation NSMutableData (MQTT)

- (void)appendByte:(UInt8)byte
{
    [self appendBytes:&byte length:1];
}

- (void)appendUInt16BigEndian:(UInt16)val
{
    [self appendByte:val / 256];
    [self appendByte:val % 256];
}

- (void)appendMQTTString:(NSString*)string
{
    UInt8 buf[2];
    const char* utf8String = [string UTF8String];
    int strLen = (int)strlen(utf8String);
    buf[0] = strLen / 256;
    buf[1] = strLen % 256;
    [self appendBytes:buf length:2];
    [self appendBytes:utf8String length:strLen];
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPacket

@implementation RHMQTTFixedHeader

- (instancetype)initWithByte:(UInt8)byte
{
    if (self = [super init]) {
        UInt8 header = byte;
        _retainFlag = header & 0x01;
        _qos = (header & 0x06) >> 1;
        _dupFlag = (header & 0x08) >> 3;
        _type = (header & 0xf0) >> 4;
    }
    return self;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPacket

@implementation RHMQTTVariableHeader

- (instancetype)init
{
    if (self = [super init]) {
        _name = @"MQIsdp";
        _version = 3;
        _connectFlags = 0x02;
        _keepAlive = 60;
    }
    return self;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPayload

@implementation RHMQTTTopic

- (instancetype)init
{
    if (self = [super init]) {
        //
    }
    return self;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPayload

@implementation RHMQTTPayload

- (instancetype)init
{
    if (self = [super init]) {
        _clientId = @"zrh";
    }
    return self;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPacket

@implementation RHMQTTPacket

- (instancetype)init
{
    if (self = [super init]) {
        _fixedHeader = [[RHMQTTFixedHeader alloc] init];
        _variableHeader = [[RHMQTTVariableHeader alloc] init];
        _payload = [[RHMQTTPayload alloc] init];
    }
    return self;
}

- (NSData *)dataWithFixedHeader
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    UInt8 header = self.fixedHeader.type << 4;
    header |= self.fixedHeader.dupFlag ? 0x08 : 0x00;
    header |= self.fixedHeader.qos << 1;
    header |= self.fixedHeader.retainFlag ? 0x01 : 0x00;
    [buffer appendBytes:&header length:1];
    return buffer;
}

- (NSData *)dataWithVariableHeader
{
    return nil;
}

- (NSData *)dataWithPayload
{
    return nil;
}

- (NSData *)data
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [buffer appendData:[self dataWithFixedHeader]];
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTConnect

@implementation RHMQTTConnect

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeConnect;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [buffer appendMQTTString:self.variableHeader.name];
    [buffer appendByte:self.variableHeader.version];
    [buffer appendByte:self.variableHeader.connectFlags];
    [buffer appendUInt16BigEndian:self.variableHeader.keepAlive];
    return buffer;
}

- (NSData *)dataWithPayload
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    
    [buffer appendMQTTString:self.payload.clientId];
    
    //TODO: username, password
    if (self.payload.username.length > 0) {
        [buffer appendMQTTString:self.payload.username];
    }//
    
    if (self.payload.password.length > 0) {
        [buffer appendMQTTString:self.payload.password];
    }//
    
    return buffer;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [buffer appendBytes:&digit length:1];
    } while (length > 0);
    
    //
    if (variableHeaderData) {
        [buffer appendData:variableHeaderData];
    }//if
    
    //
    if (payloadData) {
        [buffer appendData:payloadData];
    }//if
    
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPublish

@implementation RHMQTTPublish

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePublish;
        self.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [buffer appendMQTTString:self.variableHeader.topic];
    [buffer appendUInt16BigEndian:self.variableHeader.messageId];
    return buffer;
}

- (NSData *)dataWithPayload
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    
    if (self.payload.message.length > 0) {
        [buffer appendData:self.payload.message];
    }//if
    
    return buffer;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [buffer appendBytes:&digit length:1];
    } while (length > 0);
    
    //
    if (variableHeaderData) {
        [buffer appendData:variableHeaderData];
    }//if
    
    //
    if (payloadData) {
        [buffer appendData:payloadData];
    }//if
    
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTSubscribe

@implementation RHMQTTSubscribe

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeSubscribe;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [buffer appendUInt16BigEndian:self.variableHeader.messageId];
    return buffer;
}

- (NSData *)dataWithPayload
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [self.payload.topics enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RHMQTTTopic *temp = obj;
        [buffer appendMQTTString:temp.topic];
        [buffer appendByte:temp.qos];
    }];
    return buffer;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [buffer appendBytes:&digit length:1];
    } while (length > 0);
    
    //
    if (variableHeaderData) {
        [buffer appendData:variableHeaderData];
    }//if
    
    //
    if (payloadData) {
        [buffer appendData:payloadData];
    }//if
    
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTUnsubscribe

@implementation RHMQTTUnsubscribe

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeUnsubscribe;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [buffer appendUInt16BigEndian:self.variableHeader.messageId];
    return buffer;
}

- (NSData *)dataWithPayload
{
    NSMutableData *buffer = [[NSMutableData alloc] init];
    [self.payload.topics enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RHMQTTTopic *temp = obj;
        [buffer appendMQTTString:temp.topic];
    }];
    return buffer;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    do {
        UInt8 digit = length % 128;
        length /= 128;
        if (length > 0) {
            digit |= 0x80;
        }
        [buffer appendBytes:&digit length:1];
    } while (length > 0);
    
    //
    if (variableHeaderData) {
        [buffer appendData:variableHeaderData];
    }//if
    
    //
    if (payloadData) {
        [buffer appendData:payloadData];
    }//if
    
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTPingReq

@implementation RHMQTTPingReq

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePingReq;
    }
    return self;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    [buffer appendByte:0];
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTDisconnect

@implementation RHMQTTDisconnect

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeDisconnect;
    }
    return self;
}

- (NSData *)data
{
    NSMutableData *buffer = [NSMutableData dataWithData:[super data]];
    [buffer appendByte:0];
    return buffer;
}

@end

// ------------------------------------------

#pragma mark - RHMQTT

@implementation RHMQTT

+ (RHMQTTConnect *)connectWithClientId:(NSString *)clientId username:(NSString *)username password:(NSString *)password keepAlive:(UInt16)keepAlive cleanSession:(BOOL)cleanSession
{
    RHMQTTConnect *connect = [[RHMQTTConnect alloc] init];
    connect.variableHeader.keepAlive = keepAlive;
    connect.variableHeader.connectFlags = cleanSession ? 0x02 : 0x00;
    connect.payload.clientId = clientId;
    connect.payload.username = username;
    connect.payload.password = password;
    return connect;
}

+ (RHMQTTSubscribe *)subscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic qos:(RHMQTTQosLevel)qos
{
    RHMQTTTopic *payloadTopic = [[RHMQTTTopic alloc] init];
    payloadTopic.topic = topic;
    payloadTopic.qos = qos;
    
    RHMQTTSubscribe *subscribe = [[RHMQTTSubscribe alloc] init];
    subscribe.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;
    subscribe.variableHeader.messageId = msgId;
    subscribe.payload.topics = @[payloadTopic];
    return subscribe;
}

+ (RHMQTTUnsubscribe *)unsubscribeWithMessageId:(UInt16)msgId topic:(NSString *)topic
{
    RHMQTTTopic *payloadTopic = [[RHMQTTTopic alloc] init];
    payloadTopic.topic = topic;
    
    RHMQTTUnsubscribe *unsubscribe = [[RHMQTTUnsubscribe alloc] init];
    unsubscribe.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;
    unsubscribe.variableHeader.messageId = msgId;
    unsubscribe.payload.topics = @[payloadTopic];
    return unsubscribe;
}

@end
