#import "RCTUtilsModule.h"

@implementation RCTUtilsModule

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

+ (NSDictionary*)getWindowSize {
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat screenWidth = screenBounds.size.width * UIScreen.mainScreen.scale;
  CGFloat screenHeight = screenBounds.size.height * UIScreen.mainScreen.scale;

  NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
  [d setObject: [NSString stringWithFormat:@"%f", screenWidth] forKey: @"width"];
  [d setObject: [NSString stringWithFormat:@"%f", screenHeight] forKey: @"height"];
  return d;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(exitApp) {
  // todo
}

RCT_EXPORT_METHOD(getWindowSize:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  NSDictionary* size = [RCTUtilsModule getWindowSize];
  resolve(size);
}

RCT_EXPORT_METHOD(getSystemLocales:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve(@"zh_cn");
}

@end
