//
//  RDRadikoProgram.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/29.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RDRadikoProgram : NSObject
{
	NSString *myTitle;
	NSString *mySubtitle;
	NSString *myPerformer;
	NSString *myDescription;
	NSString *myURL;
	NSString *myInformation;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *performer;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *URL;
@property (nonatomic, retain) NSString *information;

@end
