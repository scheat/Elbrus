
#import "RDRadikoProgramGuide.h"


@implementation RDRadikoProgramGuide

- (void)initWithURL:(NSURL *)aURL
{
	
}


- (void)start
{
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	myStations = [NSMutableArray array];
	
	// launch a thread for parsing XML
	[NSThread detachNewThreadSelector:@selector(processOfParsing:) toTarget:self withObject:url];
}


- (void)processOfParsing:(NSURL *)aURL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	myCharacterData = [NSMutableData data];
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
	// create the connection with the request and start loading the data
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	// This creates a myParserContext for "push" parsing in which chunks of data that are not "well balanced" can be passed
	// to the myParserContext for streaming parsing. The handler structure defined above will be used for all the parsing. 
	// The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
	// are left blank to avoid creating a tree in memory.
	myParserContext = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, self, NULL, 0, NULL);
	[self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
	if (connection != nil)
	{
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!done);
	}
	// Release resources used only in this thread.
	xmlFreeParserCtxt(myParserContext);
	
	[pool release];
}

#pragma mark NSURLConnection Delegate methods

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}


// Forward errors to the delegate.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	done = YES;
	[self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// Process the downloaded chunk of data.
	xmlParseChunk(myParserContext, (const char *)[data bytes], [data length], 0);
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Signal the myParserContext that parsing is complete by passing "1" as the last parameter.
	xmlParseChunk(myParserContext, NULL, 0, 1);
	
	[self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
	
	// Set the condition which ends the run loop.
	done = YES;
}

static const NSUInteger kAutoreleasePoolPurgeFrequency = 20;

- (void)finishedCurrentSong
{
	[self performSelectorOnMainThread:@selector(parsedSong:) withObject:currentSong waitUntilDone:NO];
	// performSelectorOnMainThread: will retain the object until the selector has been performed
	// setting the local reference to nil ensures that the local reference will be released
	self.currentSong = nil;
	countOfParsedSongs++;
	// Periodically purge the autorelease pool. The frequency of this action may need to be tuned according to the 
	// size of the objects being parsed. The goal is to keep the autorelease pool from growing too large, but 
	// taking this action too frequently would be wasteful and reduce performance.
	if (countOfParsedSongs == kAutoreleasePoolPurgeFrequency)
	{
		[downloadAndParsePool release];
		self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
		countOfParsedSongs = 0;
	}
}


/*
 Character data is appended to a buffer until the current element ends.
 */
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length
{
	[myCharacterData appendBytes:charactersFound length:length];
}


- (NSString *)currentString
{
	// Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
	NSString *currentString = [[[NSString alloc] initWithData:myCharacterData encoding:NSUTF8StringEncoding] autorelease];
	[myCharacterData setLength:0];
	return currentString;
}

@end


#pragma mark SAX Parsing Callbacks

// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.
static const char *kName_Item = "item";
static const NSUInteger kLength_Item = 5;
static const char *kName_Title = "title";
static const NSUInteger kLength_Title = 6;
static const char *kName_Category = "category";
static const NSUInteger kLength_Category = 9;
static const char *kName_Itms = "itms";
static const NSUInteger kLength_Itms = 5;
static const char *kName_Artist = "artist";
static const NSUInteger kLength_Artist = 7;
static const char *kName_Album = "album";
static const NSUInteger kLength_Album = 6;
static const char *kName_ReleaseDate = "releasedate";
static const NSUInteger kLength_ReleaseDate = 12;

static const char *kRadikoProgramXMLStationKey = "station";
static const char *kRadikoProgramXLMScdKey = "scd";
static const char *kRadikoProgramXMLNameKey = "name";
static const char *kRadikoProgramXMLProgsKey = "progs";
static const char *kRadikoProgramXMLProgKey = "prog";
static const char *kRadikoProgramXMLTitleKey = "title";
static const char *kRadikoProgramXMLSubtitleKey = "sub_title";
static const char *kRadikoProgramXMLPfmKey = "pfm";
static const char *kRadikoProgramXMLDescKey = "desc";
static const char *kRadikoProgramXMLInfoKey = "info";
static const char *kRadikoProgramXMLUrlKey = "url";

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
	
	// The second parameter to strncmp is the name of the element, which we known from the XML schema of the feed.
	// The third parameter to strncmp is the number of characters in the element name, plus 1 for the null terminator.
	if (prefix == NULL && !strncmp((const char *)localname, kName_Item, kLength_Item))
	{
		RDRadikoStation *newStation = [[RDRadikoStation alloc] init];
		guide.currentStation = newStation;
		[newStation release];
		
		//guide.parsingASong = YES;
	}
	else if (parser.parsingASong && 
			 ((prefix == NULL && (!strncmp((const char *)localname, kName_Title, kLength_Title) ||
								  !strncmp((const char *)localname, kName_Category, kLength_Category))) ||
			  ((prefix != NULL && !strncmp((const char *)prefix, kName_Itms, kLength_Itms)) &&
			   (!strncmp((const char *)localname, kName_Artist, kLength_Artist) ||
				!strncmp((const char *)localname, kName_Album, kLength_Album) ||
				!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))) ))
	{
		parser.storingCharacters = YES;
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
	LibXMLParser *parser = (LibXMLParser *)ctx;
	if (parser.parsingASong == NO)
	{
		return;
	}
	
	if (prefix == NULL)
	{
		if (!strncmp((const char *)localname, kName_Item, kLength_Item))
		{
			[parser finishedCurrentSong];
			parser.parsingASong = NO;
		}
		else if (!strncmp((const char *)localname, kName_Title, kLength_Title))
		{
			parser.currentSong.title = [parser currentString];
		}
		else if (!strncmp((const char *)localname, kName_Category, kLength_Category))
		{
			parser.currentSong.category = [parser currentString];
		}
	}
	else if (!strncmp((const char *)prefix, kName_Itms, kLength_Itms))
	{
		if (!strncmp((const char *)localname, kName_Artist, kLength_Artist))
		{
			parser.currentSong.artist = [parser currentString];
		}
		else if (!strncmp((const char *)localname, kName_Album, kLength_Album))
		{
			parser.currentSong.album = [parser currentString];
		}
		else if (!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))
		{
			NSString *dateString = [parser currentString];
			parser.currentSong.releaseDate = [parser.parseFormatter dateFromString:dateString];
		}
	}
	parser.storingCharacters = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The parser class determines how to use the character data.
 */
static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len)
{
	LibXMLParser *parser = (LibXMLParser *)ctx;
	
	// A state variable, "storingCharacters", is set when nodes of interest begin and end. 
	// This determines whether character data is handled or ignored. 
	if (parser.storingCharacters == NO)
	{
		return;
	}
	
	[parser appendCharacters:(const char *)ch length:len];
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
