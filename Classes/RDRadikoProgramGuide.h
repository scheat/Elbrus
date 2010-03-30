//
//  RDRadikoProgramGuide.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>


@class RDRadikoStation;


@interface RDRadikoProgramGuide : NSObject
{
	xmlParserCtxtPtr myParserContext;

	NSMutableData *myCharacterData;
	
	NSMutableDictionary *myStations;
	
	NSURL *myURL;
	
	BOOL isParsingDone;
	BOOL isStoringCharacter;
	BOOL isParsingStation;
	
	RDRadikoStation *myCurrentStation;
}

@property (nonatomic, retain) RDRadikoStation *currentStation;
@property (nonatomic, assign) BOOL isParsingDone;
@property (nonatomic, assign) BOOL isStoringCharacter;
@property (nonatomic, assign) BOOL isParsingStation;

@end
