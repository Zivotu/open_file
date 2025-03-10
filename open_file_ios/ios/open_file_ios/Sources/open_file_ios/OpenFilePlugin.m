#import <Flutter/Flutter.h>
#import "OpenFilePlugin.h"

@interface OpenFilePlugin ()<UIDocumentInteractionControllerDelegate>
@end

static NSString *const CHANNEL_NAME = @"open_file";

@implementation OpenFilePlugin{
    FlutterResult _result;
    UIViewController *_viewController;
    UIDocumentInteractionController *_documentController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"open_file"
                                     binaryMessenger:[registrar messenger]];
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    OpenFilePlugin* instance = [[OpenFilePlugin alloc] initWithViewController:viewController];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _viewController = viewController;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    _result = result;
    NSString *filePath = call.arguments[@"file_path"];

    if (!filePath) {
        result([self getJson:@"The file path cannot be null" type:@-4]);
        return;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    _documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    _documentController.delegate = self;

    BOOL isAppOpen = [call.arguments[@"isIOSAppOpen"] boolValue];

    @try {
        if (isAppOpen || ![_documentController presentPreviewAnimated:YES]) {
            [self openFileWithUIActivityViewController:fileURL];
        }
    } @catch (NSException *exception) {
        result([self getJson:@"File opened incorrectly." type:@-1]);
    }
}

- (void)openFileWithUIActivityViewController:(NSURL *)fileURL {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[fileURL]
                                                        applicationActivities:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityViewController.popoverPresentationController.sourceView = _viewController.view;
        activityViewController.popoverPresentationController.sourceRect = _viewController.view.bounds;
    }

    [_viewController presentViewController:activityViewController animated:YES completion:^{ [self doneEnd]; }];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [self doneEnd];
}

- (void)doneEnd {
    NSString *json = [self getJson:@"done" type:@0];
    if (_result != nil) {
        _result(json);
        _result = nil;
    }
}

- (NSString *)getJson:(NSString *)message type:(NSNumber *)type {
    NSDictionary *dict = @{ @"message": message, @"type": type };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
