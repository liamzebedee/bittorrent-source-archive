/* BTAppController */

#import <Cocoa/Cocoa.h>
#import <python2.2/Python.h>

@interface BTAppController : NSObject
{
    IBOutlet NSTextField *url;
    IBOutlet NSWindow *urlWindow;
    NSMutableArray *dlControllers;
}
- (IBAction)cancelUrl:(id)sender;
- (IBAction)openURL:(id)sender;
- (IBAction)openTrackerResponse:(id)sender;
- (IBAction)takeUrl:(id)sender;
- (void)runWithStr:(NSString *)url controller:(id)controller;
+ (void)runWithDict:(NSDictionary *)dict;
// application delegate messages
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (void)applicationDidFinishLaunching:(NSNotification *)note;
- (NSNotificationCenter *)notificationCenter;
- (PyThreadState *)tstate;
- (void)setTstate:(PyThreadState *)nstate;
@end
