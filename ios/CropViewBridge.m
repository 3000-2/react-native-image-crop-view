#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CropView, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(sourceUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(keepAspectRatio, BOOL)
RCT_EXPORT_VIEW_PROPERTY(cropAspectRatio, CGSize)
RCT_EXPORT_VIEW_PROPERTY(iosDimensionSwapEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onCropMove, RCTDirectEventBlock)

RCT_EXTERN_METHOD(cropImage:(nonnull NSNumber *)reactTag
                 preserveTransparency:(BOOL)preserveTransparency
                 quality:(nonnull NSNumber *)quality
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rotateImage:(nonnull NSNumber *)reactTag
                 clockwise:(BOOL)clockwise)

@end