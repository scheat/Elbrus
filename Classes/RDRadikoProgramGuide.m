
#import "RDRadikoProgramGuide.h"
#import "RDRadikoLineup.h"
#import "RDRadikoProgram.h"


static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

static xmlSAXHandler simpleSAXHandlerStruct;


@interface RDRadikoProgramGuide (PrivateMethod)

- (void)processOfParsing:(NSURL *)aURL;
- (void)finishedCurrentLineup;
- (void)finishedCurrentProgram;
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length;
- (NSString *)currentString;

@end


@implementation RDRadikoProgramGuide

@synthesize delegate = mDelegate;
@synthesize currentLineup = mCurrentLineup;
@synthesize currentProgram = mCurrentProgram;
@synthesize isParsingLineup;
@synthesize isParsingProgram;
@synthesize isParsingDone;
@synthesize isStoringCharacter;

- (id)initWithURL:(NSURL *)aURL
{
	if (self = [super init])
	{
		isParsingDone = NO;
		
		mURL = [aURL retain];
	}
	
	return self;
}


- (void)start
{
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	mLineups = [NSMutableArray array];
	
	// launch a thread for parsing XML
	[NSThread detachNewThreadSelector:@selector(processOfParsing:) toTarget:self withObject:mURL];
}


- (void)dealloc
{
	[mCharacterData release];
	[mLineups release];
	[mURL release];
	[mCurrentLineup release];
	[mCurrentProgram release];
	
	[super dealloc];
}

#pragma mark NSURLConnection Delegate methods

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}


// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	isParsingDone = YES;
//	[self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// Process the downloaded chunk of data.
	xmlParseChunk(mParserContext, (const char *)[data bytes], [data length], 0);
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Signal the mParserContext that parsing is complete by passing "1" as the last parameter.
	xmlParseChunk(mParserContext, NULL, 0, 1);
	
//	[self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
	
	// Set the condition which ends the run loop.
	isParsingDone = YES;
}

@end


@implementation RDRadikoProgramGuide (PrivateMethod)

static const NSUInteger kAutoreleasePoolPurgeFrequency = 20;

- (void)processOfParsing:(NSURL *)aURL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	mCharacterData = [NSMutableData data];
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:mURL];
	// create the connection with the request and start loading the data
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	// This creates a mParserContext for "push" parsing in which chunks of data that are not "well balanced" can be passed
	// to the mParserContext for streaming parsing. The handler structure defined above will be used for all the parsing. 
	// The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
	// are left blank to avoid creating a tree in memory.
	mParserContext = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL);
	//	[self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
	if (connection != nil)
	{
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!isParsingDone);
	}
	// Release resources used only in this thread.
	xmlFreeParserCtxt(mParserContext);
	
	[pool release];
}


- (void)finishedCurrentLineup
{
	[self performSelectorOnMainThread:@selector(parsedLineup:) withObject:self.currentLineup waitUntilDone:NO];
	// performSelectorOnMainThread: will retain the object until the selector has been performed
	// setting the local reference to nil ensures that the local reference will be released
	self.currentLineup = nil;
//	countOfParsedSongs++;
//	// Periodically purge the autorelease pool. The frequency of this action may need to be tuned according to the 
//	// size of the objects being parsed. The goal is to keep the autorelease pool from growing too large, but 
//	// taking this action too frequently would be wasteful and reduce performance.
//	if (countOfParsedSongs == kAutoreleasePoolPurgeFrequency)
//	{
//		[downloadAndParsePool release];
//		self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
//		countOfParsedSongs = 0;
//	}
}


- (void)finishedCurrentProgram
{
	[self.currentLineup.programs addObject:self.currentProgram];
	self.currentProgram = nil;
}


- (void)parsedLineup:(RDRadikoLineup *)lineup
{
	if ([self.delegate respondsToSelector:@selector(guide:didParseLineup:)])
	{
		[self.delegate guide:self didParseLineup:lineup];
	}
}

/*
 Character data is appended to a buffer until the current element ends.
 */
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length
{
	[mCharacterData appendBytes:charactersFound length:length];
}


- (NSString *)currentString
{
	// Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
	NSString *currentString = [[[NSString alloc] initWithData:mCharacterData encoding:NSUTF8StringEncoding] autorelease];
	[mCharacterData setLength:0];
	return currentString;
}

@end


#pragma mark SAX Parsing Callbacks

// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.
static const char *kRadikoProgramXMLStationKey = "station";
static const NSUInteger kRadikoProgramXMLStationLength = 8;
static const char *kRadikoProgramXMLStationIDKey = "id";
static const NSUInteger kRadikoProgramXMLStationIDLength = 3;
static const char *kRadikoProgramXLMScdKey = "scd";
static const NSUInteger kRadikoProgramXMLScdLength = 4;
static const char *kRadikoProgramXMLNameKey = "name";
static const NSUInteger kRadikoProgramXMLNameLength = 5;
static const char *kRadikoProgramXMLProgsKey = "progs";
static const NSUInteger kRadikoProgramXMLProgsLength = 6;
static const char *kRadikoProgramXMLProgKey = "prog";
static const NSUInteger kRadikoProgramXMLProgLength = 5;
static const char *kRadikoProgramXMLTitleKey = "title";
static const NSUInteger kRadikoProgramXMLTitleLength = 6;
static const char *kRadikoProgramXMLSubtitleKey = "sub_title";
static const NSUInteger kRadikoProgramXMLSubtitleLength = 10;
static const char *kRadikoProgramXMLPfmKey = "pfm";
static const NSUInteger kRadikoProgramXMLPfmLength = 4;
static const char *kRadikoProgramXMLDescKey = "desc";
static const NSUInteger kRadikoProgramXMLDescLength = 5;
static const char *kRadikoProgramXMLInfoKey = "info";
static const NSUInteger kRadikoProgramXMLInfoLength = 5;
static const char *kRadikoProgramXMLUrlKey = "url";
static const NSUInteger kRadikoProgramXMLUrlLength = 4;

/*
 This callback is invoked when the parser finds the beginning of a node in the XML. For this application,
 out parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
 data about a song. In that case we create a new Song object. The other nodes of interest are several of the
 child nodes of the Song currently being parsed. For those nodes we want to accumulate the character data
 in a buffer. Some of the child nodes use a namespace prefix. 
 */
static void startElementSAX(void *ctx, 
							const xmlChar *localname, 
							const xmlChar *prefix, 
							const xmlChar *URI, 
                            int nb_namespaces, 
							const xmlChar **namespaces, 
							int nb_attributes, 
							int nb_defaulted, 
							const xmlChar **attributes)
{
	RDRadikoProgramGuide *guide = (RDRadikoProgramGuide *)ctx;
	
	// ステーション情報のパース開始
	if (prefix == NULL)
	{
		if (!strncmp((const char *)localname, kRadikoProgramXMLStationKey, kRadikoProgramXMLStationLength))
		{
			RDRadikoLineup *newLineup = [[RDRadikoLineup alloc] init];
			for (int index = 0; index < nb_attributes; index++)
			{
				if (strncmp((const char *)&attributes[index], kRadikoProgramXMLStationIDKey, kRadikoProgramXMLStationIDLength) > 0)
				{
					const xmlChar *valueBegin = attributes[index*5+3];
					const xmlChar *valueEnd = attributes[index*5+4];
					NSString *value = [[NSString alloc] initWithBytes:valueBegin 
																	  length:(valueEnd - valueBegin) 
																	 encoding:NSUTF8StringEncoding];
					newLineup.stationID = value;
				}
			}
			guide.currentLineup = newLineup;
			[newLineup release];
			
			guide.isParsingLineup = YES;
		}
		else if (guide.isParsingLineup)
		{
			if (!strncmp((const char *)localname, kRadikoProgramXMLProgKey, kRadikoProgramXMLProgLength))
			{
				RDRadikoProgram *newProgram = [[RDRadikoProgram alloc] init];
				guide.currentProgram = newProgram;
				[newProgram release];
				
				guide.isParsingProgram = YES;
			}
			else if (guide.isParsingProgram)
			{
				guide.isStoringCharacter = YES;
			}
		}
	}
	else if (guide.isParsingLineup && 
			 ((prefix == NULL && 
			   (!strncmp((const char *)localname, kRadikoProgramXMLStationKey, kRadikoProgramXMLStationLength)))))// ||
//				!strncmp((const char *)localname, kName_Category, kLength_Category))) ||
//			  ((prefix != NULL && !strncmp((const char *)prefix, kName_Itms, kLength_Itms)) &&
//			   (!strncmp((const char *)localname, kName_Artist, kLength_Artist) ||
//				!strncmp((const char *)localname, kName_Album, kLength_Album) ||
//				!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))) ))
	{
		guide.isStoringCharacter = YES;
	}
}

/*
 This callback is invoked when the parse reaches the end of a node. At that point we finish processing that node,
 if it is of interest to us. For "item" nodes, that means we have completed parsing a Song object. We pass the song
 to a method in the superclass which will eventually deliver it to the delegate. For the other nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that with the current Song object.
 */
static void	endElementSAX(void *ctx, 
						  const xmlChar *localname, 
						  const xmlChar *prefix, 
						  const xmlChar *URI)
{
	RDRadikoProgramGuide *guide = (RDRadikoProgramGuide *)ctx;
	if (guide.isParsingLineup == NO)
	{
		return;
	}
	
	if (prefix == NULL)
	{
		if (!strncmp((const char *)localname, kRadikoProgramXMLStationKey, kRadikoProgramXMLStationLength))
		{
			[guide finishedCurrentLineup];
			guide.isParsingLineup = NO;
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLNameKey, kRadikoProgramXMLNameLength))
		{
			guide.currentLineup.name = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLProgKey, kRadikoProgramXMLProgLength))
		{
			[guide finishedCurrentProgram];
			guide.isParsingProgram = NO;
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLTitleKey, kRadikoProgramXMLTitleLength))
		{
			guide.currentProgram.title = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLSubtitleKey, kRadikoProgramXMLSubtitleLength))
		{
			guide.currentProgram.subtitle = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLPfmKey, kRadikoProgramXMLPfmLength))
		{
			guide.currentProgram.performer = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLDescKey, kRadikoProgramXMLDescLength))
		{
			guide.currentProgram.description = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLUrlKey, kRadikoProgramXMLUrlLength))
		{
			guide.currentProgram.URL = [guide currentString];
		}
		else if (!strncmp((const char *)localname, kRadikoProgramXMLInfoKey, kRadikoProgramXMLInfoLength))
		{
			guide.currentProgram.information = [guide currentString];
		}
	}
//	else if (!strncmp((const char *)prefix, kName_Itms, kLength_Itms))
//	{
//		if (!strncmp((const char *)localname, kName_Artist, kLength_Artist))
//		{
//			guide.currentLineup.artist = [guide currentString];
//		}
//		else if (!strncmp((const char *)localname, kName_Album, kLength_Album))
//		{
//			guide.currentLineup.album = [guide currentString];
//		}
//		else if (!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))
//		{
//		}
//	}
	guide.isStoringCharacter = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The parser class determines how to use the character data.
 */
static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len)
{
//	NSLog(@"characters: %s", ch);
	
	RDRadikoProgramGuide *guide = (RDRadikoProgramGuide *)ctx;
	
	// A state variable, "storingCharacters", is set when nodes of interest begin and end. 
	// This determines whether character data is handled or ignored. 
	if (guide.isStoringCharacter == NO)
	{
		return;
	}
	
	[guide appendCharacters:(const char *)ch length:len];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *ctx, const char *msg, ...)
{
	// Handle errors as appropriate for your application.
	NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}


static xmlSAXHandler simpleSAXHandlerStruct = {
	NULL,                       // internalSubset
	NULL,                       // isStandalone
	NULL,                       // hasInternalSubset
	NULL,                       // hasExternalSubset
	NULL,                       // resolveEntity
	NULL,                       // getEntity
	NULL,                       // entityDecl
	NULL,                       // notationDecl
	NULL,                       // attributeDecl
	NULL,                       // elementDecl
	NULL,                       // unparsedEntityDecl
	NULL,                       // setDocumentLocator
	NULL,                       // startDocument
	NULL,                       // endDocument
	NULL,                       // startElement
	NULL,                       // endElement
	NULL,                       // reference
	charactersFoundSAX,         // characters
	NULL,                       // ignorableWhitespace
	NULL,                       // processingInstruction
	NULL,                       // comment
	NULL,                       // warning
	errorEncounteredSAX,        // error
	NULL,                       // fatalError (unused error() get all the errors)
	NULL,                       // getParameterEntity
	NULL,                       // cdataBlock
	NULL,                       // externalSubset
	XML_SAX2_MAGIC,             // initialized (The following fields are extensions ava)
	NULL,						// _private
	startElementSAX,            // startElementNs
	endElementSAX,              // endElementNs
	NULL,                       // serror
};
