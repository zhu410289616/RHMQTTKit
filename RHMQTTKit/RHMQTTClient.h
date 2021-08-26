//
//  RHMQTTClient.h
//  Pods
//
//  Created by ruhong zhu on 2021/8/21.
//

#import <Foundation/Foundation.h>
#import <RHSocketKit/RHSocketKit.h>
#import "RHMQTTPacket.h"

@class RHMQTTClient;

@protocol RHMQTTClientDelegate <NSObject>

- (void)mqttConnected:(RHMQTTClient *)mqtt host:(NSString *)host port:(int)port;
- (void)mqttDisconnect:(RHMQTTClient *)mqtt error:(NSError *)error;
- (void)mqtt:(RHMQTTClient *)mqtt received:(RHMQTTPacket *)packet;

- (void)mqtt:(RHMQTTClient *)mqtt publish:(RHMQTTPublish *)publish;

@end

@interface RHMQTTClient : NSObject

@property (nonatomic, weak) id<RHMQTTClientDelegate> delegate;

- (void)startWithHost:(NSString *)host port:(int)port;
- (void)stop;

- (void)asyncSendPacket:(RHMQTTPacket *)packet;

@end
