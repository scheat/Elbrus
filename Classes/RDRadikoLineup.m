//
//  RDRadikoLineup.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/29.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RDRadikoLineup.h"


@implementation RDRadikoLineup

@synthesize stationID = mStationID;
@synthesize name = mName;
@synthesize date = mDate;
@synthesize programs = mPrograms;

- (id)init
{
	if (self = [super init])
	{
		mPrograms = [[NSMutableArray alloc] initWithCapacity:0];
	}
	
	return self;
}


- (void)dealloc
{
	[mStationID release];
	[mName release];
	[mDate release];
	[mPrograms release];
	
	[super dealloc];
}

@end
