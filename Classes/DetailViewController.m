//
//  DetailViewController.m
//  Apfeltalk Magazin
//
//	Apfeltalk Magazin -- An iPhone Application for the site http://apfeltalk.de
//	Copyright (C) 2009	Stephan König (stephankoenig at me dot com), Stefan Kofler
//						Alexander von Below, Andreas Rami, Michael Fenske, Laurids Düllmann, Jesper Frommherz (Graphics),
//						Patrick Rollbis (Graphics),
//						
//	This program is free software; you can redistribute it and/or
//	modify it under the terms of the GNU General Public License
//	as published by the Free Software Foundation; either version 2
//	of the License, or (at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.//
//

#import "DetailViewController.h"
#import "RootViewController.h"
#import "UIScrollViewPrivate.h"


#define MAX_IMAGE_WIDTH 270


@implementation DetailViewController

@synthesize story;

 // This is the new designated initializer for the class
 - (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle story:(Story *)newStory
{
	self = [super initWithNibName:nibName bundle:nibBundle];
	if (self != nil) {
		[self setStory:newStory];
	}
	return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{	
    NSURL *loadURL = [ [ request URL ] retain ]; // retain the loadURL for use
    if ( ( [ [ loadURL scheme ] isEqualToString: @"http" ] || [ [ loadURL scheme ] isEqualToString: @"https" ] ) && ( navigationType == UIWebViewNavigationTypeLinkClicked ) ) // Check if the scheme is http/https. You can also use these for custom links to open parts of your application.
        return ![ [ UIApplication sharedApplication ] openURL: [ loadURL autorelease ] ]; // Auto release the loadurl because we wont get to release later. then return the opposite of openURL, so if safari cant open the url, open it in the UIWebView.
    [ loadURL release ];
    return YES; // URL is not http/https and should open in UIWebView
}

- (NSString *) cssStyleString {
	return @"background:transparent; font:10pt Helvetica;";
}

- (NSString *)scaledHtmlStringFromHtmlString:(NSString *)htmlString
{
    int              newHeight;
    float            scaleFactor;
    NSRange          aRange, searchRange, valueRange;
    NSMutableString *mutableString = [NSMutableString stringWithString:htmlString];

    // Scale the images to fit into the webview
	// !!!:below:20090919 This needs more cleanup, possibly with XQuery. But not today...
    searchRange = NSMakeRange(0, [mutableString length]);
    while (searchRange.location < [mutableString length])
    {
        aRange = [mutableString rangeOfString:@"width=\"" options:NSLiteralSearch range:searchRange];
        if (aRange.location != NSNotFound)
        {
            searchRange = NSMakeRange(NSMaxRange(aRange), [mutableString length] - NSMaxRange(aRange));
            aRange = [mutableString rangeOfString:@"\"" options:NSLiteralSearch range:searchRange];
            valueRange = NSMakeRange(searchRange.location, aRange.location - searchRange.location);

            scaleFactor = (float)MAX_IMAGE_WIDTH / [[mutableString substringWithRange:valueRange] intValue];
            if (scaleFactor < 1.0)
            {
                [mutableString replaceCharactersInRange:valueRange withString:[NSString stringWithFormat:@"%d", MAX_IMAGE_WIDTH]];
                searchRange = NSMakeRange(valueRange.location, [mutableString length] - valueRange.location);
                aRange = [mutableString rangeOfString:@"height=\"" options:NSLiteralSearch range:searchRange];
                if (aRange.location != NSNotFound)
                {
                    searchRange = NSMakeRange(NSMaxRange(aRange), [mutableString length] - NSMaxRange(aRange));
                    aRange = [mutableString rangeOfString:@"\"" options:NSLiteralSearch range:searchRange];
                    valueRange = NSMakeRange(searchRange.location, aRange.location - searchRange.location);
                    newHeight = [[mutableString substringWithRange:valueRange] intValue] * scaleFactor;
                    [mutableString replaceCharactersInRange:valueRange withString:[NSString stringWithFormat:@"%d", newHeight]];
                    searchRange.length = [mutableString length] - searchRange.location;
                }
            }
        }
        else
        {
            searchRange.location = [mutableString length];
        }
    }

    // !!!:MacApple:20090919 This scales all image to MAX_IMAGE_WIDTH even if they are smaller, but I have no better idea.
    [mutableString replaceOccurrencesOfString:@"class=\"resize\"" withString:[NSString stringWithFormat:@"width=%i", MAX_IMAGE_WIDTH] options:NSLiteralSearch
                                        range:NSMakeRange(0, [mutableString length])];
    return mutableString;
}

- (NSString *) htmlString {
	NSString *bodyString = [[self story] summary];
	NSRange divRange = [bodyString rangeOfString:@"</div>"];
	if (divRange.location == NSNotFound)
		return NSLocalizedString (@"Nachricht konnte nicht angezeigt werden", @"");
	
	 bodyString = [NSString stringWithFormat:@"<div style=\"%@\">\
                   <div style=\"text-align:center; font-weight:bold;\">%@</div>%@</div>", 
				   [self cssStyleString], [[self story] title],
                   [bodyString substringToIndex:divRange.location]];

	return [self scaledHtmlStringFromHtmlString:bodyString];
}


- (NSString *) rightBarButtonTitle {
	return @"Newsoptionen";
}


- (UIImage *) usedimage {
	return [UIImage imageNamed:@"header.png"];
}

- (UIImage *) thumbimage {
	NSString *thumbnailLink = [[self story] thumbnailLink];
	UIImage * thumbnailImage = nil;
	if (thumbnailLink) {
		NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbnailLink]];
		thumbnailImage = [UIImage imageWithData:imageData];
	}
	return thumbnailImage;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	webview.delegate = self;
    [webview setBackgroundColor:[UIColor clearColor]];
    [super viewDidLoad];

	// Very common
	titleLabel.text = [[self story] title];
	//[authorLabel setText:[[self story] author]];
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	if ([[self story] author] == nil) {
		datum.text = [dateFormatter stringFromDate:[[self story] date]];
	} else {
		datum.text = [NSString stringWithFormat:@"von %@ - %@", [[self story] author], [dateFormatter stringFromDate:[[self story] date]]];
	}
	[dateFormatter release];

	[thumbnail setImage:[self thumbimage]];

	//Set the title of the navigation bar
	//-150x150
	NSString * buttonTitle = [self rightBarButtonTitle];
	detailimage.image = [self usedimage];

    UIBarButtonItem *speichernButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(speichern:)];
    self.navigationItem.rightBarButtonItem = speichernButton;
    [speichernButton release];

	NSString * htmlString = [self htmlString];
	[webview loadHTMLString:htmlString baseURL:nil];
	[(UIScrollView*)[webview.subviews objectAtIndex:0]	 setAllowsRubberBanding:NO];
	[webview release];
}

-(void)playMovieAtURL:(NSURL*)theURL 

{
	[theMovie release];
	// theMovie is an iVar just for the sake of the analyzer...
    theMovie=[[MPMoviePlayerController alloc] initWithContentURL:theURL]; 
    theMovie.scalingMode=MPMovieScalingModeAspectFill; 
	
    // Register for the playback finished notification. 
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(myMovieFinishedCallback:) 
												 name:MPMoviePlayerPlaybackDidFinishNotification 
											   object:theMovie]; 
	
    // Movie playback is asynchronous, so this method returns immediately. 
    [theMovie play]; 
} 

// When the movie is done,release the controller. 
-(void)myMovieFinishedCallback:(NSNotification*)aNotification 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerPlaybackDidFinishNotification 
                                                  object:theMovie]; 
	
    // Release the movie instance created in playMovieAtURL
    [theMovie release]; 
	theMovie = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:touch.view];
	
	if(CGRectContainsPoint([thumbnail frame], location)) {
		if ([[[self story] link] rangeOfString:@".mp4"].location !=NSNotFound || [[[self story] link] rangeOfString:@".m4v"].location !=NSNotFound){
			[self playMovieAtURL:[NSURL URLWithString:[[self story] link]]];
		}
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)dealloc {
	[story release];
	[lblText release];
	[myMenu release];
	[super dealloc];
}

@end
