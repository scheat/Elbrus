//
//  RDRadikoProgramGuide.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>


@protocol RDRadikoProgramGuideDelegate;


@class RDRadikoStation;
@class RDRadikoProgram;


@interface RDRadikoProgramGuide : NSObject
{
	id<RDRadikoProgramGuideDelegate> mDelegate;
	
	xmlParserCtxtPtr mParserContext;

	NSMutableData *mCharacterData;
	
	NSMutableDictionary *mStations;
	
	NSURL *mURL;
	
	BOOL isParsingDone;
	BOOL isStoringCharacter;
	BOOL isParsingStation;
	BOOL isParsingProgram;
	
	RDRadikoStation *mCurrentStation;
	RDRadikoProgram *mCurrentProgram;
}

@property (nonatomic, assign) id<RDRadikoProgramGuideDelegate> delegate;
@property (nonatomic, retain) RDRadikoStation *currentStation;
@property (nonatomic, retain) RDRadikoProgram *currentProgram;
@property (nonatomic, assign) BOOL isParsingDone;
@property (nonatomic, assign) BOOL isStoringCharacter;
@property (nonatomic, assign) BOOL isParsingStation;
@property (nonatomic, assign) BOOL isParsingProgram;

@end


@protocol RDRadikoProgramGuideDelegate <NSObject>

@optional
- (void)guideDidEndParsingData:(RDRadikoProgramGuide *)guide;
- (void)guide:(RDRadikoProgramGuide *)guide didFailWithError:(NSError *)error;
- (void)guide:(RDRadikoProgramGuide *)guide didParseStation:(RDRadikoStation *)parsedStation;

@end
