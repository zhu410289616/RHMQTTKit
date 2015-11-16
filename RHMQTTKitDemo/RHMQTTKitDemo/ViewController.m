//
//  ViewController.m
//  RHMQTTKitDemo
//
//  Created by zhuruhong on 15/11/16.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "ViewController.h"

//RHSocket
#import "RHSocketService.h"
//MQTT
#import "RHMQTTEncoder.h"
#import "RHMQTTDecoder.h"
#import "RHMQTT.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)loadView
{
    [super loadView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectSocketServiceState:) name:kNotificationSocketServiceState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectSocketResponseData:) name:kNotificationSocketPacketResponse object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *host = @"127.0.0.1";
    int port = 1883;
    
    [RHSocketService sharedInstance].encoder = [[RHMQTTEncoder alloc] init];
    [RHSocketService sharedInstance].decoder = [[RHMQTTDecoder alloc] init];
    [[RHSocketService sharedInstance] startServiceWithHost:host port:port];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)detectSocketServiceState:(NSNotification *)notif
{
    NSLog(@"detectSocketServiceState: %@", notif);
    
    id state = notif.object;
    if (state && [state boolValue]) {
        //        RHPacketHttpRequest *req = [[RHPacketHttpRequest alloc] init];
        //        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        
        RHMQTTConnect *req = [RHMQTT connectWithClientId:@"zrh" username:nil password:nil keepAlive:60 cleanSession:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
    } else {
        //
    }//if
}

- (void)detectSocketResponseData:(NSNotification *)notif
{
    NSLog(@"detectSocketResponseData: %@", notif);
    
    RHPacketFrame *frame = notif.userInfo[@"RHSocketPacket"];
    NSLog(@"RHPacketFrame: %@", [frame data]);
    
    NSData *buffer = [frame data];
    UInt8 header = 0;
    [buffer getBytes:&header range:NSMakeRange(0, 1)];
    RHMQTTFixedHeader *fixedHeader = [[RHMQTTFixedHeader alloc] initWithByte:header];
    switch (fixedHeader.type) {
        case RHMQTTMessageTypeConnAck: {
            //finance/stock/#   finance/sotkc/ibm/+
            RHMQTTSubscribe *req = [RHMQTT subscribeWithMessageId:3 topic:@"MQTTMessenger" qos:1];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
        case RHMQTTMessageTypePubAck: {
            //qos = RHMQTTQosLevelAtLeastOnce
            NSLog(@"RHMQTTMessageTypePubAck: %d", fixedHeader.type);
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            NSLog(@"msgId: %d, ", msgId);
        }
            break;
        case RHMQTTMessageTypePubRec: {
            //qos = RHMQTTQosLevelExactlyOnce
            NSLog(@"RHMQTTMessageTypePubRec: %d", fixedHeader.type);
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            NSLog(@"msgId: %d, ", msgId);
        }
            break;
        case RHMQTTMessageTypePubRel: {
            NSLog(@"RHMQTTMessageTypePubRel: %d", fixedHeader.type);
        }
            break;
        case RHMQTTMessageTypePubComp: {
            NSLog(@"RHMQTTMessageTypePubComp: %d", fixedHeader.type);
        }
            break;
        case RHMQTTMessageTypeSubAck: {
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            UInt8 grantedQos = [[buffer subdataWithRange:NSMakeRange(4, 1)] valueFromByte];
            NSLog(@"msgId: %d, grantedQos: %d", msgId, grantedQos);
            
            RHMQTTUnsubscribe *req = [RHMQTT unsubscribeWithMessageId:msgId + 1 topic:@"MQTTMessenger"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
        case RHMQTTMessageTypeUnsubAck: {
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            NSLog(@"msgId: %d, ", msgId);
            
            RHMQTTPingReq *req = [[RHMQTTPingReq alloc] init];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
        case RHMQTTMessageTypePingResp: {
            NSLog(@"RHMQTTMessageTypePingResp: %d", fixedHeader.type);
            
            //test disconnect
            //            RHMQTTDisconnect *req = [[RHMQTTDisconnect alloc] init];
            //            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
            
            //publish
            RHMQTTPublish *req = [[RHMQTTPublish alloc] init];
            req.fixedHeader.qos = RHMQTTQosLevelExactlyOnce;//RHMQTTQosLevelAtLeastOnce;
            req.variableHeader.topic = @"MQTTMessenger";
            req.variableHeader.messageId = 99;
            req.payload.message = [@"test publish" dataUsingEncoding:NSUTF8StringEncoding];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
            
        default:
            break;
    }
    
}

@end
