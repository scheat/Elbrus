//
//  RDRadikoAreaInformation.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RDRadikoStation.h"


@interface RDRadikoAreaInformation : NSObject
{
	NSString *mAreaID;
	NSString *mAreaName;
	NSMutableArray *mStations;
	RDRadikoStation *mCurrentStation;
	
	const char *mCurrentElement;
}

@property (nonatomic, retain) NSString *areaID;
@property (nonatomic, retain) NSString *areaName;
@property (nonatomic, retain) NSMutableArray *stations;

- (id)init;
- (void)dealloc;

@end
