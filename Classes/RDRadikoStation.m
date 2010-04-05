//
//  RDRadikoStation.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RDRadikoStation.h"


@implementation RDRadikoStation

@synthesize stationID = mStationID;
@synthesize name = mName;
@synthesize link = mLink;
@synthesize logoXSmall = mLogoXSmall;
@synthesize logoSmall = mLogoSmall;
@synthesize logoMedium = mLogoMedium;
@synthesize logoLarge = mLogoLarge;
@synthesize feed = mFeed;
@synthesize banner = mBanner;

- (id)init
{
	if (self = [super init])
	{
		// do nothing
	}
	
	return self;
}


- (void)dealloc
{
	[mStationID release];
	[mName release];
	[mLink release];
	[mLogoXSmall release];
	[mLogoSmall release];
	[mLogoMedium release];
	[mLogoLarge release];
	[mFeed release];
	[mBanner release];
	
	[super dealloc];
}

@end
