//
//  RDRadikoAudioControl.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/27.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RDRadikoAudioControl.h"
#import "RDRadikoAudioSession.h"


static BOOL mySessionPrepared = NO;
static void *mySessionDelegate = NULL;


@interface RDRadikoAudioControl (AudioStreaming)

- (void)processOfStreaming;
- (void)timerDataStreaming:(NSTimer *)theTimer;

@end


@interface RDRadikoAudioControl (AudioSession)

- (BOOL)sessionPrepare:(NSError **)outError;
- (BOOL)sessionActive:(BOOL)beActive error:(NSError **)outError;
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState;

@end


@interface RDRadikoAudioControl (AudioQueue)

@property (readwrite) AudioStreamerState state;

- (void)handlePropertyFoundInStream:(AudioFileStreamID)audioStream
						 propertyID:(AudioFileStreamPropertyID)propertyID
							ioFlags:(UInt32 *)ioFlags;
- (void)handlePacketsFoundInStream:(const void *)packetBytes
					 numberOfBytes:(UInt32)numBytes
				   numberOfPackets:(UInt32)numPackets
				packetDescriptions:(AudioStreamPacketDescription *)packetDescs;
- (void)handleBufferCompleteForQueue:(AudioQueueRef)audioQueue
							  buffer:(AudioQueueBufferRef)queueBuffer;
- (void)handlePropertyChangeForQueue:(AudioQueueRef)audioQueue
						  propertyID:(AudioQueuePropertyID)propertyID;
- (void)enqueueBuffer;

@end


#pragma mark Audio Queue Callback Prototype

void MyAudioQueueOutputCallback(	void *inClientData, 
									AudioQueueRef inAQ, 
									AudioQueueBufferRef inBuffer);

void MyAudioQueueIsRunningCallback(	void *inUserData, 
									AudioQueueRef inAQ, 
									AudioQueuePropertyID inID);


#pragma mark Audio File Stream Callback Prototype

void MyPropertyListenerProc(		void *inClientData,
									AudioFileStreamID inAudioFileStream,
									AudioFileStreamPropertyID inPropertyID,
									UInt32 *ioFlags);

void MyPacketsProc(					void *inClientData,
									UInt32 inNumberBytes,
									UInt32 inNumberPackets,
									const void *inInputData,
									AudioStreamPacketDescription *inPacketDescriptions);


#pragma mark Audio Session Callback Prototype

void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);


#pragma mark Audio File Stream Callback Implementations

void MyPropertyListenerProc(		void *inClientData,
									AudioFileStreamID inAudioFileStream,
									AudioFileStreamPropertyID inPropertyID,
									UInt32 *ioFlags)
{
	RDRadikoAudioControl *audioControl = (RDRadikoAudioControl *)inClientData;
	
	[audioControl handlePropertyFoundInStream:inAudioFileStream 
								   propertyID:inPo
									  ioFlags:ioFlags];
}


void MyPacketsProc(					void *inClientData,
									UInt32 inNumberBytes,
									UInt32 inNumberPackets,
									const void *inInputData,
									AudioStreamPacketDescription *inPacketDescriptions)
{
	RDRadikoAudioControl *audioControl = (RDRadikoAudioControl *)inClientData;
	
	[audioControl handlePacketsFoundInStream:inNumberBytes
							   numberOfBytes:inNumberBytes
							 numberOfPackets:inInputData
						  packetDescriptions:inPacketDescriptions];
}


#pragma mark Audio Queue Callback Prototype

void MyAudioQueueOutputCallback(	void*						inClientData, 
									AudioQueueRef				inAQ, 
									AudioQueueBufferRef			inBuffer)
{
	RDRadikoAudioControl *audioControl = (RDRadikoAudioControl *)inClientData;
	
	[audioControl handleBufferCompleteForQueue:inAQ buffer:inBuffer];
}


void MyAudioQueueIsRunningCallback(	void *inUserData, 
									AudioQueueRef inAQ, 
									AudioQueuePropertyID inID)
{
	RDRadikoAudioControl *audioControl = (RDRadikoAudioControl *)inClientData;
	
	[audioControl handlePropertyChangeForQueue:inAQ propertyID:inID];
}


#pragma mark Audio Session Callback Prototype

void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	Class class = (Class)inClientData;
	RDRadikoAudioControl *audioControl = (RDRadikoAudioControl *)[class sessionDelegate];
	
	[audioControl handleInterruptionChangeToState:inInterruptionState];
}


@implementation RDRadikoAudioControl

@synthesize state;
@synthesize bitRate;

+ (void *)sessionDelegate
{
	return mySessionDelegate;
}


- (id)initWithURL:(NSURL *)aURL
{
	if (self = [super init])
	{
		myControlState = RadikoAudioControlStateStopped;
		
		myURL = [aURL retain];
	}
	
	return self;
}


- (void)play
{
	@synchronized (self)
	{
		if (RadikoAudioControlStatePaused == myControlState)
		{
			[self pause];
		}
		else if (RadikoAudioControlStateStopped == myControlState)
		{
			myControlState = RadikoAudioControlStateLaunching;
			
			// 再生スレッドの起動
			[NSThread detachNewThreadSelector:@selector(processOfStreaming) toTarget:self withObject:nil];
		}
	}
}


- (void)pause
{
	NSTimer *theTimer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(timerFirePauseAction:)
						  userInfo:nil repeats:NO];
	// タイマー処理をカレントスレッドのランループに登録
	[[NSRunLoop currentRunLoop] addTimer:theTimer forMode:NSDefaultRunLoopMode];
}


- (void)stop
{
	NSTimer *theTimer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(timerFireStopAction:)
											  userInfo:nil repeats:NO];
	// タイマー処理をカレントスレッドのランループに登録
	[[NSRunLoop currentRunLoop] addTimer:theTimer forMode:NSDefaultRunLoopMode];
}


- (void)dealloc
{
	[myURL release];
	
	[super dealloc];
}


@implementation RDRadikoAudioControl (AudioStreaming)

- (BOOL)openFileStream
{
	OSStatus status = noErr;
	
	@synchronized (self)
	{
		NSAssert(stream == nil && audioFileStream == nil,
				 @"audioFileStream already initialized");
		
		// Note:
		//   Radiko.jpではシステムフォーマットM4Aと仮定し固定値を設定する。
		AudioFileTypeID fileTypeHint = kAudioFileM4AType;
		// オーディオファイルストリームのオープン
		status = AudioFileStreamOpen(self, MyPropertyListenerProc, MyPacketsProc, fileTypeHint, &myAudioStream);
		if (noErr != status)
		{
			// エラーオブジェクト生成
			
			return NO;
		}
		
		// ネットワークストリームのオープン
		
		// ストリームリード処理のタイマー生成
		myStreamTimer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(timerDataStreaming:)
											  userInfo:nil repeats:YES];
		// タイマー処理をカレントスレッドのランループに登録
		[[NSRunLoop currentRunLoop] addTimer:myStreamTimer forMode:NSDefaultRunLoopMode];
	}
	
	return YES;
}


- (void)processOfStreaming
{
	BOOL success = YES;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized (self)
	{
		if (state != AS_STARTING_FILE_THREAD)
		{
			if (state != AS_STOPPING &&
				state != AS_STOPPED)
			{
				NSLog(@"### Not starting audio thread. State code is: %ld", state);
			}
			self.state = AS_INITIALIZED;
			[pool release];
			return;
		}
		
		// オーディオセッションの準備
		if (!mySessionPrepared)
		{
			success = [self sessionPrepare:error];
		}
		// オーディオセッションの有効化
		if (success)
		{
			success = [self sessionActive:YES error:error];
		}
		
		self.state = AS_WAITING_FOR_DATA;
		
		// initialize a mutex and condition so that we can block on buffers in use.
		pthread_mutex_init(&queueBuffersMutex, NULL);
		pthread_cond_init(&queueBufferReadyCondition, NULL);
		
		if (![self openFileStream])
		{
			goto cleanup;
		}
	}
	
	//
	// Process the run loop until playback is finished or failed.
	//
	BOOL isRunning = YES;
	do
	{
		isRunning = [[NSRunLoop currentRunLoop]
					 runMode:NSDefaultRunLoopMode
					 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		
		//
		// If there are no queued buffers, we need to check here since the
		// handleBufferCompleteForQueue:buffer: should not change the state
		// (may not enter the synchronized section).
		//
		if (buffersUsed == 0 && self.state == AS_PLAYING)
		{
			err = AudioQueuePause(audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_BUFFERING;
		}
	} while (isRunning && ![self runLoopShouldExit]);
	
cleanup:
	
	@synchronized(self)
	{
		//
		// Cleanup the read stream if it is still open
		//
		if (stream)
		{
			CFReadStreamClose(stream);
			CFRelease(stream);
			stream = nil;
		}
		
		//
		// Close the audio file strea,
		//
		if (audioFileStream)
		{
			err = AudioFileStreamClose(audioFileStream);
			audioFileStream = nil;
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_CLOSE_FAILED];
			}
		}
		
		//
		// Dispose of the Audio Queue
		//
		if (audioQueue)
		{
			err = AudioQueueDispose(audioQueue, true);
			audioQueue = nil;
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_DISPOSE_FAILED];
			}
		}
		
		pthread_mutex_destroy(&queueBuffersMutex);
		pthread_cond_destroy(&queueBufferReadyCondition);
		
		[self sessionActive:NO error:error];
		
		bytesFilled = 0;
		packetsFilled = 0;
		seekTime = 0;
		seekNeeded = NO;
		self.state = AS_INITIALIZED;
	}
	
	[pool release];
}


- (void)timerDataStreaming:(NSTimer *)theTimer
{
	UInt8 bytes[kAQBufSize];
	CFIndex length;
	
	@synchronized (self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		// データのダウンロードおよびパース
		length = CFReadStreamRead(stream, bytes, kAQBufSize);
		
		if (length == -1)
		{
			[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
			return;
		}
		
		if (length == 0)
		{
			return;
		}
	}
	
	if (discontinuous)
	{
		err = AudioFileStreamParseBytes(audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
		if (err)
		{
			[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
			return;
		}
	}
	else
	{
		err = AudioFileStreamParseBytes(audioFileStream, length, bytes, 0);
		if (err)
		{
			[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
			return;
		}
	}
}


- (void)timerFirePauseAction:(NSTimer *)theTimer
{
	OSStatus status = noErr;
	
	@synchronized (self)
	{
		if (state == RadikoAudioControlStatePlaying)
		{
			status = AudioQueueStop(myAudioQueue, true);
			if (noErr != status)
			{
				return;
			}
			
			myControlState = RadikoAudioControlStatePaused;
		}
		else if (state == RadikoAudioControlStatePaused)
		{
			myControlState = RadikoAudioControlStateStarting;
			
			// オーディオキューの開始を待つ
			status = AudioQueueStart(myAudioQueue, NULL);
			if (status)
			{
				return;
			}
		}
	}
}


- (void)timerFireStopAction:(NSTimer *)theTimer
{
	@synchronized (self)
	{
		if (audioQueue &&
			(state == AS_PLAYING || state == AS_PAUSED ||
			 state == AS_BUFFERING || state == AS_WAITING_FOR_QUEUE_TO_START))
		{
			self.state = AS_STOPPING;
			stopReason = AS_STOPPING_USER_ACTION;
			err = AudioQueueStop(audioQueue, true);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_STOP_FAILED];
				return;
			}
		}
		else if (state != AS_INITIALIZED)
		{
			self.state = AS_STOPPED;
			stopReason = AS_STOPPING_USER_ACTION;
		}
	}
	
	while (state != AS_INITIALIZED)
	{
		[NSThread sleepForTimeInterval:0.1];
	}
}

@end


@implementation RDRadikoAudioControl (AudioQueue)

- (void)enqueueBuffer
{
	@synchronized (self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		inuse[fillBufferIndex] = true;		// set in use flag
		buffersUsed++;
		
		// enqueue buffer
		AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
		fillBuf->mAudioDataByteSize = bytesFilled;
		
		if (packetsFilled)
		{
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
		}
		else
		{
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
		}
		
		if (err)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_ENQUEUE_FAILED];
			return;
		}
		
		
		if (state == AS_BUFFERING ||
			state == AS_WAITING_FOR_DATA ||
			(state == AS_STOPPED && stopReason == AS_STOPPING_TEMPORARILY))
		{
			//
			// Fill all the buffers before starting. This ensures that the
			// AudioFileStream stays a small amount ahead of the AudioQueue to
			// avoid an audio glitch playing streaming files on iPhone SDKs < 3.0
			//
			if (buffersUsed == kNumAQBufs - 1)
			{
				if (self.state == AS_BUFFERING)
				{
					err = AudioQueueStart(audioQueue, NULL);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
					self.state = AS_PLAYING;
				}
				else
				{
					self.state = AS_WAITING_FOR_QUEUE_TO_START;
					
					err = AudioQueueStart(audioQueue, NULL);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
				}
			}
		}
		
		// go to next buffer
		if (++fillBufferIndex >= kNumAQBufs) fillBufferIndex = 0;
		bytesFilled = 0;		// reset bytes filled
		packetsFilled = 0;		// reset packets filled
	}
	
	// wait until next buffer is not in use
	pthread_mutex_lock(&queueBuffersMutex); 
	while (inuse[fillBufferIndex])
	{
		pthread_cond_wait(&queueBufferReadyCondition, &queueBuffersMutex);
	}
	pthread_mutex_unlock(&queueBuffersMutex);
}


- (void)handlePropertyFoundInStream:(AudioFileStreamID)audioStream
						 propertyID:(AudioFileStreamPropertyID)propertyID
							ioFlags:(UInt32 *)ioFlags
{
	@synchronized (self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets)
		{
			discontinuous = true;
			
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			
			// get the stream format.
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
			
			sampleRate = asbd.mSampleRate;
			
			// create the audio queue
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_CREATION_FAILED];
				return;
			}
			
			// start the queue if it has not been started already
			// listen to the "isRunning" property
			err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, self);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_ADD_LISTENER_FAILED];
				return;
			}
			
			// allocate audio queue buffers
			for (unsigned int i = 0; i < kNumAQBufs; ++i)
			{
				err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
				if (err)
				{
					[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED];
					return;
				}
			}
			
			// get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			OSStatus ignorableError;
			ignorableError = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (ignorableError)
			{
				return;
			}
			
			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			ignorableError = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (ignorableError)
			{
				return;
			}
			
			// set the cookie on the queue.
			ignorableError = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (ignorableError)
			{
				return;
			}
		}
		else if (inPropertyID == kAudioFileStreamProperty_DataOffset)
		{
			SInt64 offset;
			UInt32 offsetSize = sizeof(offset);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataOffset, &offsetSize, &offset);
			dataOffset = offset;
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
		}
	}
}


- (void)handlePacketsFoundInStream:(const void *)packetBytes
					 numberOfBytes:(UInt32)numBytes
				   numberOfPackets:(UInt32)numPackets
				packetDescriptions:(AudioStreamPacketDescription *)packetDescs
{
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (bitRate == 0)
		{
			UInt32 dataRateDataSize = sizeof(UInt32);
			err = AudioFileStreamGetProperty(
											 audioFileStream,
											 kAudioFileStreamProperty_BitRate,
											 &dataRateDataSize,
											 &bitRate);
			if (err)
			{
				//
				// m4a and a few other formats refuse to parse the bitrate so
				// we need to set an "unparseable" condition here. If you know
				// the bitrate (parsed it another way) you can set it on the
				// class if needed.
				//
				bitRate = ~0;
			}
		}
		
		// we have successfully read the first packests from the audio stream, so
		// clear the "discontinuous" flag
		discontinuous = false;
	}
	
	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i)
		{
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			size_t bufSpaceRemaining;
			
			@synchronized(self)
			{
				// If the audio was terminated before this point, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				if (packetSize > kAQBufSize)
				{
					[self failWithErrorCode:AS_AUDIO_BUFFER_TOO_SMALL];
				}
				
				bufSpaceRemaining = kAQBufSize - bytesFilled;
			}
			
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			if (bufSpaceRemaining < packetSize)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)inInputData + packetOffset, packetSize);
				
				// fill out packet description
				packetDescs[packetsFilled] = inPacketDescriptions[i];
				packetDescs[packetsFilled].mStartOffset = bytesFilled;
				// keep track of bytes filled and packets filled
				bytesFilled += packetSize;
				packetsFilled += 1;
			}
			
			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
			if (packetsDescsRemaining == 0) {
				[self enqueueBuffer];
			}
		}	
	}
	else
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
			if (bufSpaceRemaining < inNumberBytes)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				bufSpaceRemaining = kAQBufSize - bytesFilled;
				size_t copySize;
				if (bufSpaceRemaining < inNumberBytes)
				{
					copySize = bufSpaceRemaining;
				}
				else
				{
					copySize = inNumberBytes;
				}
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)(inInputData + offset), copySize);
				
				
				// keep track of bytes filled and packets filled
				bytesFilled += copySize;
				packetsFilled = 0;
				inNumberBytes -= copySize;
				offset += copySize;
			}
		}
	}
}


- (void)handleBufferCompleteForQueue:(AudioQueueRef)audioQueue
							  buffer:(AudioQueueBufferRef)queueBuffer
{
	unsigned int bufIndex = -1;
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		if (inBuffer == audioQueueBuffer[i])
		{
			bufIndex = i;
			break;
		}
	}
	
	if (bufIndex == -1)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_MISMATCH];
		pthread_mutex_lock(&queueBuffersMutex);
		pthread_cond_signal(&queueBufferReadyCondition);
		pthread_mutex_unlock(&queueBuffersMutex);
		return;
	}
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&queueBuffersMutex);
	inuse[bufIndex] = false;
	buffersUsed--;
	
	pthread_cond_signal(&queueBufferReadyCondition);
	pthread_mutex_unlock(&queueBuffersMutex);
}


- (void)handlePropertyChangeForQueue:(AudioQueueRef)audioQueue
						  propertyID:(AudioQueuePropertyID)propertyID
{
	@synchronized (self)
	{
		if (kAudioQueueProperty_IsRunning == propertyID)
		{
			if (RadikoAudioControlStateStopping == myControlState)
			{
				myControlState = RadikoAudioControlStateStopped;
			}
			else if (RadikoAudioControlStateStarting == myControlState)
			{
				myControlState = RadikoAudioControlStatePlaying;
			}
		}
	}
}


- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState
{
	if (inInterruptionState == kAudioSessionBeginInterruption ||
		inInterruptionState == kAudioSessionEndInterruption)
	{
		// 他のタイマー処理をランループから取り除く
		
		// ポーズアクションを発効
		[self pause];
	}
}

@end


@implementation RDRadikoAudioControl (AudioSession)

- (BOOL)sessionPrepare:(NSError **)outError;
{
	OSStatus status = noErr;
	
	// Note:
	//   AudioSessionInitialize(inRunLoop, inRunLoopMode, inInterruptionListener, *inClientData)
	//     1: コールバック実行のランループ。NULLを設定する場合、メインのランループ上で実行。
	//     2: ランループの実行モード。NULLを設定する場合、kCFRunLoopDefaultModeを設定。
	//     3: コールバック関数。
	//     4: コールバック関数に渡すデータ。
	status = AudioSessionInitialize(NULL, NULL, MyAudioSessionInterruptionListener, [self class]);
	if (noErr != status)
	{
		// エラーオブジェクト生成
		
		return NO;
	}
	
	return YES;
}


- (BOOL)sessionActive:(BOOL)beActive error:(NSError **)outError;
{
	// Note:
	//   画面がロックされた場合も再生を継続する場合、kAudioSessionCategory_MediaPlaybackを設定する必要あり。
	UInt32 category = kAudioSessionCategory_MediaPlayback;
	status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	if (noErr != status)
	{
		// エラーオブジェクト生成
		
		return NO;
	}
	
	// オーディオセッションのデリゲートを設定
	mySessionDelegate = ((beActive) ? (void *)self : NULL);
	
	// オーディオセッションの有効化/無効化を設定
	OSStatus status = AudioSessionSetActive(((beActive) ? true : false));
	if (noErr != status)
	{
		// エラーオブジェクト生成
		
		mySessionDelegate = NULL;
		
		return NO;
	}
	
	return YES;
}


- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState
{
	
}

@end

