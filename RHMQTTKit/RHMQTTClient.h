//
//  RHMQTTClient.h
//  Pods
//
//  Created by ruhong zhu on 2021/8/21.
//

#import <Foundation/Foundation.h>
#import <RHSocketKit/RHSocketKit.h>
#import "RHMQTTPacket.h"

@interface RHMQTTClient : NSObject

- (void)addDelegate:(id<RHSocketChannelDelegate>)delegate;

- (void)startWithHost:(NSString *)host port:(int)port;
- (void)stop;

- (void)asyncSendPacket:(RHMQTTPacket *)packet;

@end
