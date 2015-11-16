//
//  RHMQTTDecoder.m
//  RHSocketKitDemo
//
//  Created by zhuruhong on 15/11/6.
//  Copyright © 2015年 zhuruhong. All rights reserved.
//

#import "RHMQTTDecoder.h"
#import "RHMQTT.h"

@interface RHMQTTDecoder ()
{
    NSMutableData *_receiveData;
}

@end

@implementation RHMQTTDecoder

- (instancetype)init
{
    if (self = [super init]) {
        _receiveData = [[NSMutableData alloc] init];
    }
    return self;
}

- (NSUInteger)decodeData:(NSData *)data decoderOutput:(id<RHSocketDecoderOutputDelegate>)output tag:(long)tag
{
    @synchronized(self) {
        if (data.length < 1) {
            return _receiveData.length;
        }
        [_receiveData appendData:data];
        
        NSUInteger headIndex = 0;
        NSUInteger lengthMultiplier = 1;
        //先读区2个字节的协议长度 (前2个字节为数据包的固定长度)
        while (_receiveData && (_receiveData.length - headIndex) >= (1 + lengthMultiplier)) {
            NSData *lenData = [_receiveData subdataWithRange:NSMakeRange(headIndex, 1 + lengthMultiplier)];
            
            //剩余长度remainingLength（1-4个字节，可变）
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
            
            if (_receiveData.length - headIndex < remainingLength + 2) {
                break;
            }
            NSData *frameData = [_receiveData subdataWithRange:NSMakeRange(headIndex, remainingLength + 2)];
            RHPacketFrame *frame = [[RHPacketFrame alloc] initWithData:frameData];
            [output didDecode:frame tag:tag];
            headIndex += remainingLength + 2;
        }
        NSData *remainData = [_receiveData subdataWithRange:NSMakeRange(headIndex, _receiveData.length-headIndex)];
        [_receiveData setData:remainData];
        
        return _receiveData.length;
    }//@synchronized
}

@end
