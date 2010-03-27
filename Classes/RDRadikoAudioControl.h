//
//  RDRadikoAudioControl.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/27.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@class RDRadikoAudioControl;

@interface RDRadikoAudioControl : NSObject
{
@private
	NSURL *myURL;
	
	AudioQueueRef myAudioQueue;
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];
	
	AudioFileStreamID myAudioStream;
	
	NSTimer *myStreamTimer;
	
	enum {
		RadikoAudioControlStateLaunching = 0,	// 再生スレッド起動中
		RadikoAudioControlStateLaunched,		// 再生スレッド起動終了
		RadikoAudioControlStateWaiting,			// 再生開始に必要なデータ待ち
		RadikoAudioControlStateStarting,		// オーディオキューの開始中
		RadikoAudioControlStateBuffering,		// データのバッファリング中
		RadikoAudioControlStatePlaying,			// オーディオ再生中
		RadikoAudioControlStatePaused,			// オーディオ一時停止中
		RadikoAudioControlStateStopping,		// オーディオキューの停止中
		RadikoAudioControlStateStopped			// オーディオ停止中
	} myControlState;
}

+ (void *)sessionDelegate;

- (void)play;
- (void)stop;
- (void)pause;

@end
