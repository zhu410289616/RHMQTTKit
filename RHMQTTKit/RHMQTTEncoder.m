//
//  RHMQTTEncoder.m
//  RHMQTTKitDemo
//
//  Created by zhuruhong on 16/2/23.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "RHMQTTEncoder.h"
#import "RHMQTTPacket.h"

@implementation RHMQTTEncoder

- (void)encode:(id<RHUpstreamPacket>)upstreamPacket output:(id<RHSocketEncoderOutputProtocol>)output
{
    RHMQTTPacket *packet = (RHMQTTPacket *)upstreamPacket;
    NSData *data = [packet data];
    NSMutableData *sendData = [NSMutableData dataWithData:data];
    
    NSTimeInterval timeout = [upstreamPacket timeout];
    
    RHSocketLog(@" timeout: %f, data: %@", timeout, sendData);
    [output didEncode:sendData timeout:timeout];
}

@end
