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

- (void)addDelegate:(id<RHSocketChannelDelegate>)delegate
{
    [self.tcpChannel.channel addDelegate:delegate];
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
    RHSocketPacketResponse *frame = (RHSocketPacketResponse *)packet;
    RHSocketLog(@"[RHMQTT] RHPacketFrame: %@", [frame object]);
    
    NSData *buffer = [frame object];
    UInt8 header = 0;
    [buffer getBytes:&header range:NSMakeRange(0, 1)];
    RHMQTTFixedHeader *fixedHeader = [[RHMQTTFixedHeader alloc] initWithByte:header];
    switch (fixedHeader.type) {
        case RHMQTTMessageTypeConnAck:
        {
            RHSocketLog(@"RHMQTTMessageTypeConnAck: %d", fixedHeader.type);
            [self.tcpChannel.config.channelBeats start];
        }
            break;
        case RHMQTTMessageTypePublish: {
            RHSocketLog(@"RHMQTTMessageTypePublish: %d", fixedHeader.type);
            RHMQTTPublish *publish = [[RHMQTTPublish alloc] initWithObject:buffer];
            RHSocketLog(@"publish payload: %@", [publish dataWithPayload]);
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
        case RHMQTTMessageTypePubRec:
        {
            //qos = RHMQTTQosLevelExactlyOnce
            RHSocketLog(@"RHMQTTMessageTypePubRec: %d", fixedHeader.type);
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            RHSocketLog(@"msgId: %d, ", msgId);
        }
            break;
            
        default:
            break;
    }
}

@end
