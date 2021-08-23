//
//  RHMQTTClient.m
//  Pods
//
//  Created by ruhong zhu on 2021/8/21.
//

#import "RHMQTTClient.h"
#import "RHMQTTDecoder.h"
#import "RHMQTTEncoder.h"

@interface RHMQTTClient () <RHSocketChannelDelegate>

@property (nonatomic, strong) RHChannelService *tcpChannel;
@property (nonatomic, strong) RHSocketConnectParam *connectParam;

@end

@implementation RHMQTTClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tcpChannel = [[RHChannelService alloc] init];
    }
    return self;
}

- (void)startWithHost:(NSString *)host port:(int)port
{
    self.connectParam = [[RHSocketConnectParam alloc] init];
    self.connectParam.host = host;
    self.connectParam.port = port;
    self.connectParam.heartbeatInterval = 15;
    self.connectParam.heartbeatEnabled = YES;
    self.connectParam.autoReconnect = NO;
    
    RHChannelBeats *beats = [[RHChannelBeats alloc] init];
    beats.heartbeatBlock = ^id<RHUpstreamPacket>{
        return [[RHMQTTPingReq alloc] init];
    };
    
    [self.tcpChannel.channel addDelegate:self];
    [self.tcpChannel startWithConfig:^(RHChannelConfig *config) {
        config.encoder = [[RHMQTTEncoder alloc] init];
        config.decoder = [[RHMQTTDecoder alloc] init];
        config.channelBeats = beats;
        config.connectParam = self.connectParam;
    }];
}

- (void)stop
{
    [self.tcpChannel stopService];
}

- (void)asyncSendPacket:(RHMQTTPacket *)packet
{
    [self.tcpChannel asyncSendPacket:packet];
}

#pragma mark - RHSocketChannelDelegate

- (void)channelOpened:(RHSocketChannel *)channel host:(NSString *)host port:(int)port
{
    RHSocketLog(@"[RHMQTT] channelOpened: %@:%@", host, @(port));
    
    //需要在password_file.conf文件中设置帐号密码
    NSString *username = @"";//@"testuser";
    NSString *password = @"";//@"testuser";
    RHMQTTConnect *connect = [RHMQTTConnect connectWithClientId:@"RHMQTTKit" username:username password:password keepAlive:60 cleanSession:YES];
    [self asyncSendPacket:connect];
}

- (void)channelClosed:(RHSocketChannel *)channel error:(NSError *)error
{
    RHSocketLog(@"[RHMQTT] channelClosed: %@", error);
    [self.tcpChannel.config.channelBeats stop];
}

- (void)channel:(RHSocketChannel *)channel received:(id<RHDownstreamPacket>)packet
{
    if (![packet isKindOfClass:[RHMQTTPacket class]]) {
        RHSocketLog(@"[RHMQTT] packet(%@) is not kind of RHMQTTPacket", NSStringFromClass([packet class]));
        return;
    }
    
    RHMQTTPacket *mqttPacket = (RHMQTTPacket *)packet;
    RHSocketLog(@"[RHMQTT] mqttPacket object: %@", [mqttPacket object]);
    
    NSData *buffer = mqttPacket.object;
    RHMQTTFixedHeader *fixedHeader = mqttPacket.fixedHeader;
    switch (fixedHeader.type) {
        case RHMQTTMessageTypeConnAck:
        {
            RHSocketLog(@"RHMQTTMessageTypeConnAck: %d", fixedHeader.type);
            [self.tcpChannel.config.channelBeats start];
        }
            break;
        case RHMQTTMessageTypePublish: {
            RHSocketLog(@"RHMQTTMessageTypePublish: %d", fixedHeader.type);
            RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] initWithData:buffer];
            int16_t topicLength = [byteBuffer readInt16:2 endianSwap:YES];
            RHMQTTVariableHeader *variableHeader = [[RHMQTTVariableHeader alloc] init];
            variableHeader.topic = [byteBuffer readString:2+2 length:topicLength];
            variableHeader.messageId = [byteBuffer readInt16:2+2+topicLength endianSwap:YES];
            RHMQTTPublish *publish = [[RHMQTTPublish alloc] initWithObject:buffer];
            publish.fixedHeader = fixedHeader;
            publish.variableHeader = variableHeader;
            
            /**
             兄弟，针对QoS2，为了便于说明，我们先假设一个方向，Server -> Client：
             ----PUBLISH--->
             <----PUBREC----
             ----PUBREL---->
             <----PUBCOMP---
             */
            if (fixedHeader.qos == RHMQTTQosLevelAtLeastOnce) {
                /**
                 作为订阅者/服务器接收（QoS level = 1）PUBLISH消息之后对发送者的响应。
                 */
                RHMQTTPublishAck *publishAck = [[RHMQTTPublishAck alloc] initWithMessageId:variableHeader.messageId];
                [self asyncSendPacket:publishAck];
            } else if (fixedHeader.qos == RHMQTTQosLevelExactlyOnce) {
                /**
                 作为订阅者/服务器对QoS level = 2的发布PUBLISH消息的发送方的响应，确认已经收到，为QoS level = 2消息流的第二个消息。 和PUBACK相比，除了消息类型不同外，其它都是一样。
                 */
                RHMQTTPublishRec *publishRec = [[RHMQTTPublishRec alloc] initWithMessageId:variableHeader.messageId];
                [self asyncSendPacket:publishRec];
            }
        }
            break;
        case RHMQTTMessageTypePubAck: {
            RHSocketLog(@"RHMQTTMessageTypePubAck: %d", fixedHeader.type);
            RHSocketByteBuf *byteBuffer = [[RHSocketByteBuf alloc] initWithData:buffer];
            RHMQTTVariableHeader *variableHeader = [[RHMQTTVariableHeader alloc] init];
            variableHeader.messageId = [byteBuffer readInt16:2 endianSwap:YES];
            RHMQTTPublish *publish = [[RHMQTTPublish alloc] init];
            publish.fixedHeader = fixedHeader;
            publish.variableHeader = variableHeader;
        }
            break;
        case RHMQTTMessageTypePubRec:
        {
            //qos = RHMQTTQosLevelExactlyOnce
            RHSocketLog(@"RHMQTTMessageTypePubRec: %d", fixedHeader.type);
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            RHSocketLog(@"msgId: %d, ", msgId);
        }
            break;
        case RHMQTTMessageTypeSubAck:
        {
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            UInt8 grantedQos = [[buffer subdataWithRange:NSMakeRange(4, 1)] valueFromByte];
            RHSocketLog(@"msgId: %d, grantedQos: %d", msgId, grantedQos);
        }
            break;
        case RHMQTTMessageTypePingResp:
        {
            RHSocketLog(@"RHMQTTMessageTypePingResp: %d", fixedHeader.type);
        }
            break;
            
        default:
            break;
    }
}

@end
