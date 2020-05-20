//
//  SoundEffect.h
//  OpenGLES-004
//
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>

@interface SoundEffect : NSObject {
  
  SystemSoundID _soundID;
  
}


+ (instancetype)soundEffectWithContentsOfFile:(NSString *)aPath;

- (instancetype)initWithContentsOfFile:(NSString *)path;

- (void)play;


@end


