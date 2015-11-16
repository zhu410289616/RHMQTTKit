//
//  RHMQTTEncoder.m
//  RHSocketKitDemo
//
//  Created by zhuruhong on 15/11/6.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "RHMQTTEncoder.h"
#import "RHSocketConfig.h"

@implementation RHMQTTEncoder

- (void)encodePacket:(id<RHSocketPacketContent>)packet encoderOutput:(id<RHSocketEncoderOutputDelegate>)output
{
    NSData *data = [packet data];
    NSMutableData *sendData = [NSMutableData dataWithData:data];
    
    NSTimeInterval timeout = [packet timeout];
    NSInteger tag = [packet tag];
    RHSocketLog(@"tag:%ld, timeout: %f, data: %@", (long)tag, timeout, sendData);
    [output didEncode:sendData timeout:timeout tag:tag];
}

@end
