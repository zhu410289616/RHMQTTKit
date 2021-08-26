//
//  RHMQTTPacket.m
//  Pods
//
//  Created by ruhong zhu on 2021/8/21.
//

#import "RHMQTTPacket.h"

// ------------------------------------------

#pragma mark - RHMQTTFixedHeader

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

#pragma mark - RHMQTTVariableHeader

@implementation RHMQTTVariableHeader

@synthesize object = _object;

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

- (instancetype)initWithObject:(id)aObject
{
    if (self = [super init]) {
        _object = aObject;
    }
    return self;
}

@end

// ------------------------------------------

#pragma mark - RHMQTTTopic

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

+ (RHMQTTConnect *)connectWithClientId:(NSString *)clientId username:(NSString *)username password:(NSString *)password keepAlive:(UInt16)keepAlive cleanSession:(BOOL)cleanSession
{
    RHMQTTConnect *connect = [[RHMQTTConnect alloc] init];
    connect.variableHeader.keepAlive = keepAlive;
    connect.variableHeader.connectFlags = cleanSession ? 0x02 : 0x00;
    connect.payload.clientId = clientId;
    connect.payload.username = username;
    connect.payload.password = password;
    if (username.length > 0) {
        connect.variableHeader.connectFlags = connect.variableHeader.connectFlags | 0x80;
    }
    if (password.length > 0) {
        connect.variableHeader.connectFlags = connect.variableHeader.connectFlags | 0x40;
    }
    return connect;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeConnect;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeInt16:self.variableHeader.name.length endianSwap:YES];
    [byteBuffer writeString:self.variableHeader.name];
    [byteBuffer writeInt8:self.variableHeader.version];
    [byteBuffer writeInt8:self.variableHeader.connectFlags];
    [byteBuffer writeInt16:self.variableHeader.keepAlive endianSwap:YES];
    return [byteBuffer data];
}

- (NSData *)dataWithPayload
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    
    [byteBuffer writeInt16:self.payload.clientId.length endianSwap:YES];
    [byteBuffer writeString:self.payload.clientId];
    
    if (self.payload.username.length > 0) {
        [byteBuffer writeInt16:self.payload.username.length endianSwap:YES];
        [byteBuffer writeString:self.payload.username];
    }
    
    if (self.payload.password.length > 0) {
        [byteBuffer writeInt16:self.payload.password.length endianSwap:YES];
        [byteBuffer writeString:self.payload.password];
    }
    
    return [byteBuffer data];
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    [byteBuffer writeData:[RHSocketUtils dataWithRawVarint32:length]];
    [byteBuffer writeData:variableHeaderData];
    [byteBuffer writeData:payloadData];
    
    return [byteBuffer data];
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
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeInt16:self.variableHeader.topic.length endianSwap:YES];
    [byteBuffer writeString:self.variableHeader.topic];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
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
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    [byteBuffer writeData:[RHSocketUtils dataWithRawVarint32:length]];
    [byteBuffer writeData:variableHeaderData];
    [byteBuffer writeData:payloadData];
    
    return [byteBuffer data];
}

@end

@implementation RHMQTTPublishAck

- (instancetype)initWithMessageId:(int16_t)msgId
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePubAck;
        self.variableHeader.messageId = msgId;
    }
    return self;
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:2];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

@end

@implementation RHMQTTPublishRec

- (instancetype)initWithMessageId:(int16_t)msgId
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePubRec;
        self.variableHeader.messageId = msgId;
    }
    return self;
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:2];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

@end

@implementation RHMQTTPublishRel

- (instancetype)initWithMessageId:(int16_t)msgId
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePubRel;
        self.variableHeader.messageId = msgId;
    }
    return self;
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:2];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

@end

@implementation RHMQTTPublishComp

- (instancetype)initWithMessageId:(int16_t)msgId
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypePubComp;
        self.variableHeader.messageId = msgId;
    }
    return self;
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:2];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

@end

// ------------------------------------------

#pragma mark - RHMQTTSubscribe

@implementation RHMQTTSubscribe

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

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeSubscribe;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

- (NSData *)dataWithPayload
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [self.payload.topics enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RHMQTTTopic *temp = obj;
        [byteBuffer writeInt16:temp.topic.length endianSwap:YES];
        [byteBuffer writeString:temp.topic];
        [byteBuffer writeInt8:temp.qos];
    }];
    return [byteBuffer data];
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    [byteBuffer writeData:[RHSocketUtils dataWithRawVarint32:length]];
    [byteBuffer writeData:variableHeaderData];
    [byteBuffer writeData:payloadData];
    
    return [byteBuffer data];
}

@end

// ------------------------------------------

#pragma mark - RHMQTTUnsubscribe

@implementation RHMQTTUnsubscribe

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

- (instancetype)init
{
    if (self = [super init]) {
        self.fixedHeader.type = RHMQTTMessageTypeUnsubscribe;
    }
    return self;
}

- (NSData *)dataWithVariableHeader
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeInt16:self.variableHeader.messageId endianSwap:YES];
    return [byteBuffer data];
}

- (NSData *)dataWithPayload
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [self.payload.topics enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RHMQTTTopic *temp = obj;
        [byteBuffer writeInt16:temp.topic.length endianSwap:YES];
        [byteBuffer writeString:temp.topic];
    }];
    return [byteBuffer data];
}

- (NSData *)data
{
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    
    NSData *variableHeaderData = [self dataWithVariableHeader];
    NSData *payloadData = [self dataWithPayload];
    
    //remaining length
    NSUInteger length = variableHeaderData.length + payloadData.length;
    [byteBuffer writeData:[RHSocketUtils dataWithRawVarint32:length]];
    [byteBuffer writeData:variableHeaderData];
    [byteBuffer writeData:payloadData];
    
    return [byteBuffer data];
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
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:0];
    return [byteBuffer data];
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
    RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] init];
    [byteBuffer writeData:[self dataWithFixedHeader]];
    [byteBuffer writeInt8:0];
    return [byteBuffer data];
}

@end
