#if __has_include(<Flutter/Flutter.h>)
#import <Flutter/Flutter.h>
#else
#import "Flutter.h"
#endif

@interface OpenFilePlugin : NSObject<FlutterPlugin>
@end

@interface UIDocumentInteractionControllerDelegate
@end
