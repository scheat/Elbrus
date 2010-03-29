//
//  RDRadikoStation.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/29.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
							

@interface RDRadikoStation : NSObject
{
	NSString *myStationID;
	NSString *myName;
	NSString *myDate;
	NSMutableArray *myPrograms;
}

@property (nonatomic, retain) NSString *stationID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) NSMutableArray *programs;

@end
