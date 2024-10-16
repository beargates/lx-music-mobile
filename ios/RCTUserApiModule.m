#import "RCTUserApiModule.h"

@implementation RCTUserApiModule

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

+ (NSDictionary*)getWindowSize {
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat screenWidth = screenBounds.size.width;
  CGFloat screenHeight = screenBounds.size.height;

  NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
  [d setObject:@"width" forKey: [NSString stringWithFormat:@"%f", screenWidth]];
  [d setObject:@"height" forKey: [NSString stringWithFormat:@"%f", screenHeight]];
  return d;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(destroy)
{
  
}

@end
