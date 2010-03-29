//
//  RDRadikoProgramGuide.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>


@interface RDRadikoProgramGuide : NSObject
{
	xmlParserCtxtPtr myParserContext;

	NSMutableData *myCharacterData;
	
	NSMutableDictionary *myStations;
	
	
	RDRadikoStation *myCurrentStation;
}

@property (nonatomic, retain) RDRadikoStation *currentStation;

@end
