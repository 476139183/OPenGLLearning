//
//  SoundEffect.m
//  OpenGLES-004
//
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "SoundEffect.h"

@implementation SoundEffect

//从指定的声音文件中创建系统声音效果对象
+ (instancetype)soundEffectWithContentsOfFile:(NSString *)aPath {
  if (aPath) {
    return [[SoundEffect alloc] initWithContentsOfFile:aPath];
  }
  return nil;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
 
  self = [super init];
  
  if (self) {
    ///! 获取声音文件路径
    NSURL *aFileURL = [NSURL fileURLWithPath:path isDirectory:NO];
    
    ///! 判断文件是否存在
    if (aFileURL == nil) {
      NSLog(@"文件不存在");
      return nil;
    }
    
    ///! 定义 SystemSoundID
    SystemSoundID aSoundID;
    
    // 允许系统播放声音
    OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(aFileURL), &aSoundID);
    
    if (error != kAudioSessionNoError) {
     
      NSLog(@"load sound Path Error");
      return nil;
    }
    
    //! 赋值
    _soundID = aSoundID;
    
  }
  
  return self;
}

- (void)dealloc {
 
  ///! 清除声音对象 以及 相关资源
  AudioServicesDisposeSystemSoundID(_soundID);
  
}

- (void)play {

  ///! 播放音频
  AudioServicesPlaySystemSound(_soundID);
  
}

@end
