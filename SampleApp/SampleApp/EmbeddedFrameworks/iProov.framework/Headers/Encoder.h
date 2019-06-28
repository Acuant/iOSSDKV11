//
//  Encoder.h
//  iProov
//
//  Created by Jonathan Ellis on 28/04/2015.
//  Copyright (c) 2015 iProov Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>

@class Encoder;

@protocol EncoderDelegate <NSObject>

- (void)encoder:(Encoder *)encoder didEncodeFrame:(NSData *)data;

@end

@interface Encoder : NSObject

@property (nonatomic, weak) id<EncoderDelegate> delegate;

- (id)initWithHDCapable:(BOOL)isHDCapable;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)finish;
//+ (CMSampleBufferRef)cropSampleBuffer:(CMSampleBufferRef)sampleBuffer toRect:(CGRect)cropRect;

@end
