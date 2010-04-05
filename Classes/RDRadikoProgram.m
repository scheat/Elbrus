//
//  RDRadikoProgram.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/29.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RDRadikoProgram.h"


@implementation RDRadikoProgram

@synthesize title = mTitle;
@synthesize subtitle = mSubtitle;
@synthesize performer = mPerformer;
@synthesize description = mDescription;
@synthesize URL = mURL;
@synthesize information = mInformation;

- (id)init
{
	if (self = [super init])
	{
		
	}
	
	return self;
}


- (void)dealloc
{
	[mTitle release];
	[mSubtitle release];
	[mPerformer release];
	[mDescription release];
	[mURL release];
	[mInformation release];
	
	[super dealloc];
}

@end
