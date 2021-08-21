//
//  ViewController.m
//  RHMQTTKitDemo
//
//  Created by zhuruhong on 15/11/16.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "ViewController.h"

#import <RHMQTTKit/RHMQTT.h>

//RHSocket
#import "RHSocketService.h"
//MQTT
#import "RHMQTTEncoder.h"
#import "RHMQTTDecoder.h"
#import "RHMQTT.h"

@interface ViewController () <RHSocketChannelDelegate>
{
    UITextField *_hostTextField;
    UITextField *_portTextField;
    
    UIButton *_connectButton;
    UIButton *_disconnectButton;
    UIButton *_subscribeButton;
    UIButton *_unsubscribeButton;
    UIButton *_pingReqButton;
    UIButton *_publishButton;
    
    UITextView *_receivedTextView;
}

@property (nonatomic, strong) RHMQTTClient *mqttClient;

@end

@implementation ViewController

- (void)loadView
{
    [super loadView];
    self.mqttClient = [[RHMQTTClient alloc] init];
    [self.mqttClient addDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _hostTextField = [[UITextField alloc] init];
    _hostTextField.frame = CGRectMake(20, 40, 200, 50);
    _hostTextField.borderStyle = UITextBorderStyleRoundedRect;
    _hostTextField.font = [UIFont systemFontOfSize:15];
    _hostTextField.text = @"mq.tongxinmao.com";
    [self.view addSubview:_hostTextField];
    
    _portTextField = [[UITextField alloc] init];
    _portTextField.frame = CGRectMake(20, CGRectGetMaxY(_hostTextField.frame) + 10, 200, 50);
    _portTextField.borderStyle = UITextBorderStyleRoundedRect;
    _portTextField.font = [UIFont systemFontOfSize:15];
    _portTextField.text = @"18830";
    [self.view addSubview:_portTextField];
    
    _connectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _connectButton.frame = CGRectMake(20, CGRectGetMaxY(_portTextField.frame) + 20, 130, 40);
    _connectButton.layer.borderColor = [UIColor blackColor].CGColor;
    _connectButton.layer.borderWidth = 0.5;
    _connectButton.layer.masksToBounds = YES;
    [_connectButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_connectButton setTitle:@"connect" forState:UIControlStateNormal];
    [_connectButton addTarget:self action:@selector(doConnectButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_connectButton];
    
    _subscribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _subscribeButton.frame = CGRectMake(20, CGRectGetMaxY(_connectButton.frame) + 20, 130, 40);
    _subscribeButton.layer.borderColor = [UIColor blackColor].CGColor;
    _subscribeButton.layer.borderWidth = 0.5;
    _subscribeButton.layer.masksToBounds = YES;
    [_subscribeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_subscribeButton setTitle:@"subscribe" forState:UIControlStateNormal];
    [_subscribeButton addTarget:self action:@selector(doSubscribeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_subscribeButton];
    
    _pingReqButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _pingReqButton.frame = CGRectMake(20, CGRectGetMaxY(_subscribeButton.frame) + 20, 130, 40);
    _pingReqButton.layer.borderColor = [UIColor blackColor].CGColor;
    _pingReqButton.layer.borderWidth = 0.5;
    _pingReqButton.layer.masksToBounds = YES;
    [_pingReqButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_pingReqButton setTitle:@"ping" forState:UIControlStateNormal];
    [_pingReqButton addTarget:self action:@selector(doPingButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pingReqButton];
    
    //
    _disconnectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _disconnectButton.frame = CGRectMake(160, CGRectGetMaxY(_portTextField.frame) + 20, 130, 40);
    _disconnectButton.layer.borderColor = [UIColor blackColor].CGColor;
    _disconnectButton.layer.borderWidth = 0.5;
    _disconnectButton.layer.masksToBounds = YES;
    [_disconnectButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_disconnectButton setTitle:@"disconnect" forState:UIControlStateNormal];
    [_disconnectButton addTarget:self action:@selector(doDisconnectButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_disconnectButton];
    
    _unsubscribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _unsubscribeButton.frame = CGRectMake(160, CGRectGetMaxY(_disconnectButton.frame) + 20, 130, 40);
    _unsubscribeButton.layer.borderColor = [UIColor blackColor].CGColor;
    _unsubscribeButton.layer.borderWidth = 0.5;
    _unsubscribeButton.layer.masksToBounds = YES;
    [_unsubscribeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_unsubscribeButton setTitle:@"unsubscribe" forState:UIControlStateNormal];
    [_unsubscribeButton addTarget:self action:@selector(doUnsubscribeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_unsubscribeButton];
    
    _publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _publishButton.frame = CGRectMake(160, CGRectGetMaxY(_unsubscribeButton.frame) + 20, 130, 40);
    _publishButton.layer.borderColor = [UIColor blackColor].CGColor;
    _publishButton.layer.borderWidth = 0.5;
    _publishButton.layer.masksToBounds = YES;
    [_publishButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_publishButton setTitle:@"publish" forState:UIControlStateNormal];
    [_publishButton addTarget:self action:@selector(doPublishButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_publishButton];
    
    CGFloat x = CGRectGetMinX(_connectButton.frame);
    CGFloat y = CGRectGetMaxY(_pingReqButton.frame) + 20;
    CGFloat width = CGRectGetWidth(self.view.frame) - x - x;
    CGFloat height = CGRectGetHeight(self.view.frame) - y - 60;
    _receivedTextView = [[UITextView alloc] init];
    _receivedTextView.frame = CGRectMake(x, y, width, height);
    _receivedTextView.layer.borderColor = [UIColor blackColor].CGColor;
    _receivedTextView.layer.borderWidth = 0.5f;
    _receivedTextView.layer.masksToBounds = YES;
    _receivedTextView.font = [UIFont systemFontOfSize:20];
    _receivedTextView.text = @"MQTT Log:\n";
    [self.view addSubview:_receivedTextView];
}

- (void)doConnectButtonAction
{
    NSString *host = _hostTextField.text.length > 5 ? _hostTextField.text : @"127.0.0.1";
    int port = _portTextField.text.length > 1 ? [_portTextField.text intValue] : 1883;
    [self.mqttClient startWithHost:host port:port];
}

- (void)doSubscribeButtonAction
{
    NSString *topic = @"MQTT/Messenger/#";
    [self showCommand:@"Subscribe" log:topic];
    
    //finance/stock/#   finance/sotkc/ibm/+
    RHMQTTSubscribe *req = [RHMQTTSubscribe subscribeWithMessageId:3 topic:topic qos:1];
    [self.mqttClient asyncSendPacket:req];
}

- (void)doPingButtonAction
{
    [self showCommand:@"ping" log:@""];
    
    RHMQTTPingReq *req = [[RHMQTTPingReq alloc] init];
    [self.mqttClient asyncSendPacket:req];
}

- (void)doDisconnectButtonAction
{
    [self showCommand:@"Disconnect" log:@""];
    
    RHMQTTDisconnect *req = [[RHMQTTDisconnect alloc] init];
    [self.mqttClient asyncSendPacket:req];
}

- (void)doUnsubscribeButtonAction
{
    NSString *topic = @"MQTT/Messenger/#";
    [self showCommand:@"Unsubscribe" log:topic];
    
    RHMQTTUnsubscribe *req = [RHMQTTUnsubscribe unsubscribeWithMessageId:22 topic:topic];
    [self.mqttClient asyncSendPacket:req];
}

- (void)doPublishButtonAction
{
    NSString *topic = @"MQTT/Messenger/rh";
    [self showCommand:@"Publish" log:topic];
    
    RHMQTTPublish *req = [[RHMQTTPublish alloc] init];
    req.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;//RHMQTTQosLevelExactlyOnce
    req.variableHeader.topic = topic;
    req.variableHeader.messageId = 99;
    req.payload.message = [@"test publish" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mqttClient asyncSendPacket:req];
}

- (void)showCommand:(NSString *)command log:(NSString *)log
{
    NSMutableString *logStr = [NSMutableString string];
    [logStr appendFormat:@"%@\n", _receivedTextView.text];
    [logStr appendFormat:@"%@: %@\n", command, log];
    _receivedTextView.text = logStr;
}

#pragma mark - RHSocketChannelDelegate

- (void)channelOpened:(RHSocketChannel *)channel host:(NSString *)host port:(int)port
{
    _connectButton.hidden = YES;
    
    NSString *topic = [NSString stringWithFormat:@"%@:%@", host, @(port)];
    [self showCommand:@"Connected" log:topic];
}

- (void)channelClosed:(RHSocketChannel *)channel error:(NSError *)error
{
    _connectButton.hidden = NO;
    
    NSString *topic = [NSString stringWithFormat:@"%@", error];
    [self showCommand:@"Disconnect" log:topic];
}

- (void)channel:(RHSocketChannel *)channel received:(id<RHDownstreamPacket>)packet
{
    RHSocketLog(@"[RHMQTT] received: %@", packet);
    
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
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData ConnAck" log:topic];
        }
            break;
        case RHMQTTMessageTypePublish: {
            RHSocketLog(@"RHMQTTMessageTypePublish: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData Publish" log:topic];
            
            RHMQTTPublish *publish = [[RHMQTTPublish alloc] initWithObject:buffer];
            RHSocketLog(@"publish payload: %@", [publish dataWithPayload]);
        }
            break;
        case RHMQTTMessageTypePubAck: {
            //qos = RHMQTTQosLevelAtLeastOnce
            RHSocketLog(@"RHMQTTMessageTypePubAck: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData PubAck" log:topic];
            
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            NSLog(@"msgId: %d, ", msgId);
        }
            break;
        case RHMQTTMessageTypePubRec: {
            //qos = RHMQTTQosLevelExactlyOnce
            RHSocketLog(@"RHMQTTMessageTypePubRec: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData PubRec" log:topic];
            
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            RHSocketLog(@"msgId: %d, ", msgId);
        }
            break;
        case RHMQTTMessageTypePubRel: {
            RHSocketLog(@"RHMQTTMessageTypePubRel: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData PubRel" log:topic];
        }
            break;
        case RHMQTTMessageTypePubComp: {
            RHSocketLog(@"RHMQTTMessageTypePubComp: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData PubComp" log:topic];
        }
            break;
        case RHMQTTMessageTypeSubAck:
        {
            RHSocketLog(@"RHMQTTMessageTypeSubAck: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData SubAck" log:topic];
            
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            UInt8 grantedQos = [[buffer subdataWithRange:NSMakeRange(4, 1)] valueFromByte];
            RHSocketLog(@"msgId: %d, grantedQos: %d", msgId, grantedQos);
        }
            break;
        case RHMQTTMessageTypePingResp:
        {
            RHSocketLog(@"RHMQTTMessageTypePingResp: %d", fixedHeader.type);
            NSString *topic = [RHSocketUtils hexStringFromData:buffer];
            [self showCommand:@"ReceivedData PingResp" log:topic];
        }
            break;
            
        default:
            break;
    }
}

@end
