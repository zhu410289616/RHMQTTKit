//
//  RHMQTTDecoder.m
//  RHMQTTKitDemo
//
//  Created by zhuruhong on 16/2/23.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "RHMQTTDecoder.h"
#import "RHMQTTPacket.h"

@implementation RHMQTTDecoder

- (NSInteger)decode:(id<RHDownstreamPacket>)downstreamPacket output:(id<RHSocketDecoderOutputProtocol>)output
{
    NSData *downstreamData = [downstreamPacket object];
    NSUInteger headIndex = 0;
    NSUInteger lengthMultiplier = 1;
    //先读区2个字节的协议长度 (前2个字节为数据包的固定长度)
    while (downstreamData && (downstreamData.length - headIndex) >= (1 + lengthMultiplier)) {
        NSData *lenData = [downstreamData subdataWithRange:NSMakeRange(headIndex, 1 + lengthMultiplier)];
        
        //剩余长度remainingLength（1-4个字节，可变）
        //可变头部内容字节长度 + Playload/负荷字节长度 = 剩余长度
        NSUInteger remainingLength = 0;
        UInt8 digit = 0;
        [lenData getBytes:&digit range:NSMakeRange(lengthMultiplier, 1)];
        
        if ((digit & 0x80) == 0x00) {
            //已经读区到剩余长度，可以解码
            remainingLength += (digit & 0x7f);
        } else {
            lengthMultiplier++;
            remainingLength += (digit & 0x7f);
            NSAssert(lengthMultiplier <= 4, @"remain length error ...");
            continue;
        }
        
        if (downstreamData.length - headIndex < remainingLength + 2) {
            break;
        }
        NSData *frameData = [downstreamData subdataWithRange:NSMakeRange(headIndex, remainingLength + 2)];
        RHMQTTPacket *packet = [[RHMQTTPacket alloc] initWithObject:frameData];
        [output didDecode:packet];
        headIndex += remainingLength + 2;
    }
    return headIndex;
}

@end
