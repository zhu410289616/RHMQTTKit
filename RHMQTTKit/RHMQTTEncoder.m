//
//  RHMQTTEncoder.m
//  RHMQTTKitDemo
//
//  Created by zhuruhong on 16/2/23.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "RHMQTTEncoder.h"
#import "RHMQTTPacket.h"
#import "RHSocketUtils.h"

@implementation RHMQTTEncoder

- (void)encode:(id<RHUpstreamPacket>)upstreamPacket output:(id<RHSocketEncoderOutputProtocol>)output
{
    RHMQTTPacket *packet = (RHMQTTPacket *)upstreamPacket;
    NSData *data = [packet data];
    NSMutableData *sendData = [NSMutableData dataWithData:data];
    
    NSTimeInterval timeout = [upstreamPacket timeout];
    
    RHSocketLog(@"[encode] timeout: %f, data: %@", timeout, [RHSocketUtils hexStringFromData:sendData]);
    [output didEncode:sendData timeout:timeout];
}

@end
