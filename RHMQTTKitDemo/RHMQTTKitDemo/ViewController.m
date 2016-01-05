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
#import "RHMQTTCodec.h"
#import "RHMQTT.h"
#import "RHPacketResponse.h"

@interface ViewController ()
{
    UITextField *_hostTextField;
    UITextField *_portTextField;
    
    UIButton *_connectButton;
    UIButton *_disconnectButton;
    UIButton *_subscribeButton;
    UIButton *_unsubscribeButton;
    UIButton *_pingReqButton;
    UIButton *_publishButton;
}

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
    
    _hostTextField = [[UITextField alloc] init];
    _hostTextField.frame = CGRectMake(20, 40, 200, 50);
    _hostTextField.borderStyle = UITextBorderStyleRoundedRect;
    _hostTextField.font = [UIFont systemFontOfSize:15];
    _hostTextField.text = @"127.0.0.1";
    [self.view addSubview:_hostTextField];
    
    _portTextField = [[UITextField alloc] init];
    _portTextField.frame = CGRectMake(20, CGRectGetMaxY(_hostTextField.frame) + 10, 200, 50);
    _portTextField.borderStyle = UITextBorderStyleRoundedRect;
    _portTextField.font = [UIFont systemFontOfSize:15];
    _portTextField.text = @"1883";
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
    
}

- (void)doConnectButtonAction
{
    NSString *host = _hostTextField.text.length > 5 ? _hostTextField.text : @"127.0.0.1";
    int port = _portTextField.text.length > 1 ? [_portTextField.text intValue] : 1883;
    
    [RHSocketService sharedInstance].codec = [[RHMQTTCodec alloc] init];
    [[RHSocketService sharedInstance] startServiceWithHost:host port:port];
}

- (void)doSubscribeButtonAction
{
    //finance/stock/#   finance/sotkc/ibm/+
    RHMQTTSubscribe *req = [RHMQTT subscribeWithMessageId:3 topic:@"MQTTMessenger" qos:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
}

- (void)doPingButtonAction
{
    RHMQTTPingReq *req = [[RHMQTTPingReq alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
}

- (void)doDisconnectButtonAction
{
    RHMQTTDisconnect *req = [[RHMQTTDisconnect alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
}

- (void)doUnsubscribeButtonAction
{
    RHMQTTUnsubscribe *req = [RHMQTT unsubscribeWithMessageId:22 topic:@"MQTTMessenger"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
}

- (void)doPublishButtonAction
{
    RHMQTTPublish *req = [[RHMQTTPublish alloc] init];
    req.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;//RHMQTTQosLevelExactlyOnce
    req.variableHeader.topic = @"MQTTMessenger";
    req.variableHeader.messageId = 99;
    req.payload.message = [@"test publish" dataUsingEncoding:NSUTF8StringEncoding];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
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
        _connectButton.hidden = YES;
        
        RHMQTTConnect *req = [RHMQTT connectWithClientId:@"zrh" username:nil password:nil keepAlive:60 cleanSession:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
    } else {
        _connectButton.hidden = NO;
    }//if
}

- (void)detectSocketResponseData:(NSNotification *)notif
{
    NSLog(@"detectSocketResponseData: %@", notif);
    
    RHPacketResponse *frame = notif.userInfo[@"RHSocketPacket"];
    NSLog(@"RHPacketFrame: %@", [frame data]);
    
    NSData *buffer = [frame data];
    UInt8 header = 0;
    [buffer getBytes:&header range:NSMakeRange(0, 1)];
    RHMQTTFixedHeader *fixedHeader = [[RHMQTTFixedHeader alloc] initWithByte:header];
    switch (fixedHeader.type) {
        case RHMQTTMessageTypeConnAck: {
            NSLog(@"RHMQTTMessageTypeConnAck: %d", fixedHeader.type);
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
            
            //
//            RHMQTTUnsubscribe *req = [RHMQTT unsubscribeWithMessageId:msgId + 1 topic:@"MQTTMessenger"];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
            
            //
            RHMQTTPingReq *req = [[RHMQTTPingReq alloc] init];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
        case RHMQTTMessageTypeUnsubAck: {
            UInt16 msgId = [[buffer subdataWithRange:NSMakeRange(2, 2)] valueWithBytes];
            NSLog(@"msgId: %d, ", msgId);
            
            RHMQTTPingReq *req = [[RHMQTTPingReq alloc] init];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
        case RHMQTTMessageTypePingResp: {
            NSLog(@"RHMQTTMessageTypePingResp: %d", fixedHeader.type);
            
            //test disconnect
            //            RHMQTTDisconnect *req = [[RHMQTTDisconnect alloc] init];
            //            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
            
            //publish
            RHMQTTPublish *req = [[RHMQTTPublish alloc] init];
            req.fixedHeader.qos = RHMQTTQosLevelAtLeastOnce;//RHMQTTQosLevelExactlyOnce
            req.variableHeader.topic = @"MQTTMessenger";
            req.variableHeader.messageId = 99;
            req.payload.message = [@"test publish" dataUsingEncoding:NSUTF8StringEncoding];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSocketPacketRequest object:req];
        }
            break;
            
        default:
            break;
    }
    
}

@end
