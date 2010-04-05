//
//  RDRadikoAreaInformation.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <libxml/tree.h>

#import "RDRadikoAreaInformation.h"
#import "RDRadikoStation.h"


static const NSString * const kRadikoURL = @"http://radiko.jp/";
static NSString * const kRadikoLineupParam = @"station";

static const char *kRadikoAreaXMLStationsKey = "stations";
static const NSUInteger kRadikoAreaXMLStationsLength = 9;
static const char *kRadikoAreaXMLIDKey = "area_id";
static const NSUInteger kRadikoAreaXMLIDLength = 8;
static const char *kRadikoAreaXMLNameKey = "area_name";
static const NSUInteger kRadikoAreaXMLNameLength = 10;
static const char *kRadikoAreaXMLStationKey = "station";
static const NSUInteger kRadikoAreaXMLStationLength = 8;
static const char *kRadikoStationXMLIDKey = "id";
static const NSUInteger kRadikoStationXMLIDLength = 3;
static const char *kRadikoStationXMLNameKey = "name";
static const NSUInteger kRadikoStationXMLNameLength = 5;
static const char *kRadikoStationXMLLinkKey = "href";
static const NSUInteger kRadikoStationXMLLinkLength = 5;
static const char *kRadikoStationXMLLogoXSmallKey = "logo_xsmall";
static const NSUInteger kRadikoStationXMLLogoXSmallLength = 12;
static const char *kRadikoStationXMLLogoSmallKey = "logo_small";
static const NSUInteger kRadikoStationXMLLogoSmallLength = 11;
static const char *kRadikoStationXMLLogoMediumKey = "logo_medium";
static const NSUInteger kRadikoStationXMLLogoMediumLength = 12;
static const char *kRadikoStationXMLLogoLargeKey = "logo_large";
static const NSUInteger kRadikoStationXMLLogoLargeLength = 11;
static const char *kRadikoStationXMLFeedKey = "feed";
static const NSUInteger kRadikoStationXMLFeedLength = 5;
static const char *kRadikoStationXMLBannerKey = "banner";
static const NSUInteger kRadikoStationXMLBannerLength = 7;


@interface RDRadikoAreaInformation (ParseDocument)

- (NSString *)downloadAreaInformation;
- (BOOL)registerAreaInformation;

@end



@implementation RDRadikoAreaInformation

@synthesize areaID = mAreaID;
@synthesize areaName = mAreaName;
@synthesize stations = mStations;

- (id)init
{
	if (self = [super init])
	{
		mStations = [[NSMutableArray alloc] initWithCapacity:0];
		
		[self registerAreaInformation];
	}
	
	return self;
}


- (void)dealloc
{
	[mAreaID release];
	[mAreaName release];
	[mStations release];
	
	[super dealloc];
}

@end


@implementation RDRadikoAreaInformation (ParseDocument)

- (NSString *)downloadAreaInformation
{
	// Note:
	//   Safari on Mac OS Xからのリクエスト
	//     GET /station/ HTTP/1.1
	//     Host: radiko.jp
	//     Pragma: no-cache
	//     Accept: application/xml, text/xml, */*
	//     Cache-Control: no-cache
	//     Referer: http://radiko.jp/
	//     Expires: Thu, 01 Jan 1970 00:00:00 GMT
	//     X-Requested-With: XMLHttpRequest
	//     Accept-Language: ja-jp
	//     Accept-Encoding: gzip, deflate
	//     Connection: keep-alive
	
	NSString *URLString = [kRadikoURL stringByAppendingString:kRadikoLineupParam];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:URLString]];
	[request addValue:@"no-cache" forHTTPHeaderField:@"Pragma"];
	[request addValue:@"application/xml, text/xml, */*" forHTTPHeaderField:@"Accept"];
	[request addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
	[request addValue:@"ja-jp" forHTTPHeaderField:@"Accept-Language"];
	[request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
	
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


- (BOOL)registerAreaInformation
{
	char *xmlChars = [[self downloadAreaInformation] UTF8String];
	
	xmlDoc *xmlDoc = NULL;
	xmlNode *xmlNode = NULL;
	
	xmlDoc = xmlReadMemory(xmlChars, strlen(xmlChars), "", NULL, 0);
	if (NULL != xmlDoc)
	{
		xmlNode = xmlDocGetRootElement(xmlDoc);
		[self parseStations:xmlNode];
		
		if (mCurrentStation)
		{
			[self.stations addObject:mCurrentStation];
		}
		[self printAreaInfo];
	}
	else
	{
		xmlFreeDoc(xmlDoc);
	}
	
	xmlCleanupParser();
	
	return YES;
}


- (void)parseStations:(xmlNode *)aNode
{
	xmlNode *currentNode = NULL;
	
	for (currentNode = aNode; currentNode; currentNode = currentNode->next)
	{
		if (currentNode->type == XML_ELEMENT_NODE)
		{
			mCurrentElement = (const char *)currentNode->name;
//			printf("node type: Element, name: %s\n", currentNode->name);
			if (!strncmp((const char *)mCurrentElement, kRadikoAreaXMLStationKey, kRadikoAreaXMLStationLength))
			{
				if (mCurrentStation)
				{
					[mStations addObject:mCurrentStation];
				}
				mCurrentStation = [[[RDRadikoStation alloc] init] autorelease];
			}
			
			if (currentNode->properties)
			{
				xmlAttr *attr = currentNode->properties;
				[self parseAreaInfo:attr];
			}
		}
		else if (currentNode->type == XML_TEXT_NODE)
		{
			if (!strncmp(mCurrentElement, kRadikoStationXMLIDKey, kRadikoStationXMLIDLength))
			{
				mCurrentStation.stationID = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLNameKey, kRadikoStationXMLNameLength))
			{
				mCurrentStation.name = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLLinkKey, kRadikoStationXMLLinkLength))
			{
				mCurrentStation.link = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLLogoXSmallKey, kRadikoStationXMLLogoXSmallLength))
			{
				mCurrentStation.logoXSmall = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLLogoSmallKey, kRadikoStationXMLLogoSmallLength))
			{
				mCurrentStation.logoSmall = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLLogoMediumKey, kRadikoStationXMLLogoMediumLength))
			{
				mCurrentStation.logoMedium = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLLogoLargeKey, kRadikoStationXMLLogoLargeLength))
			{
				mCurrentStation.logoLarge = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLFeedKey, kRadikoStationXMLFeedLength))
			{
				mCurrentStation.feed = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
			else if (!strncmp(mCurrentElement, kRadikoStationXMLBannerKey, kRadikoStationXMLBannerLength))
			{
				mCurrentStation.banner = [NSString stringWithUTF8String:(const char *)currentNode->content];
			}
//			printf("node type: Text, content: %s\n", currentNode->content);
		}
		
		[self parseStations:currentNode->children];
	}
}


- (void)parseAreaInfo:(xmlAttr *)aAttr
{
	xmlAttr *currentAttr = NULL;
	
	if (strncmp((const char *)mCurrentElement, kRadikoAreaXMLStationsKey, kRadikoAreaXMLStationsLength))
	{
		return;
	}
	
	for (currentAttr = aAttr; currentAttr; currentAttr = currentAttr->next)
	{
		if (currentAttr->type == XML_ATTRIBUTE_NODE && currentAttr->children)
		{
			xmlNode *node = currentAttr->children;
			if ((node->type == XML_TEXT_NODE) &&
				!strncmp((const char *)node->content, kRadikoAreaXMLIDKey, kRadikoAreaXMLIDLength))
			{
				self.areaID = [NSString stringWithUTF8String:(const char *)node->content];
			}
			if ((node->type == XML_TEXT_NODE) &&
				!strncmp((const char *)node->content, kRadikoAreaXMLNameKey, kRadikoAreaXMLNameLength))
			{
				self.areaName = [NSString stringWithUTF8String:(const char *)node->content];
			}
		}
	}
}


- (void)printAreaInfo
{
	NSLog(@"stations: %d", [mStations count]);
}

@end

