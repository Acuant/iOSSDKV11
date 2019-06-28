//
//  InvertFilter.h
//  Pods
//
//  Created by Jonathan Ellis on 01/02/2017.
//
//

#import <GPUImage/GPUImageFilter.h>

@interface FlashingFilter : GPUImageFilter
{
    GLint uniformNextRGB;
    GLint uniformLineRGB;
}

- (void)setR:(float)R G:(float)G B:(float)B;
- (void)setLineR:(float)R G:(float)G B:(float)B;

@end
