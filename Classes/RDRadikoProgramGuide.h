//
//  RDRadikoProgramGuide.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

#import "RDRadikoLineup.h"
#import "RDRadikoProgram.h"


@protocol RDRadikoProgramGuideDelegate;


@interface RDRadikoProgramGuide : NSObject
{
	id<RDRadikoProgramGuideDelegate> mDelegate;
	
	xmlParserCtxtPtr mParserContext;

	NSMutableData *mCharacterData;
	
	NSMutableDictionary *mLineups;
	
	NSURL *mURL;
	
	BOOL isParsingDone;
	BOOL isStoringCharacter;
	BOOL isParsingLineup;
	BOOL isParsingProgram;
	
	RDRadikoLineup *mCurrentLineup;
	RDRadikoProgram *mCurrentProgram;
}

@property (nonatomic, assign) id<RDRadikoProgramGuideDelegate> delegate;
@property (nonatomic, retain) RDRadikoLineup *currentLineup;
@property (nonatomic, retain) RDRadikoProgram *currentProgram;
@property (nonatomic, assign) BOOL isParsingDone;
@property (nonatomic, assign) BOOL isStoringCharacter;
@property (nonatomic, assign) BOOL isParsingLineup;
@property (nonatomic, assign) BOOL isParsingProgram;

- (id)initWithURL:(NSURL *)aURL;
- (void)start;
- (void)dealloc;

@end


@protocol RDRadikoProgramGuideDelegate <NSObject>

@optional
- (void)guideDidEndParsingData:(RDRadikoProgramGuide *)guide;
- (void)guide:(RDRadikoProgramGuide *)guide didFailWithError:(NSError *)error;
- (void)guide:(RDRadikoProgramGuide *)guide didParseLineup:(RDRadikoLineup *)parsedLineup;

@end
