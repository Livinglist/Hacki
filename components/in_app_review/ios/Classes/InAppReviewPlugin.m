#import "InAppReviewPlugin.h"

@import StoreKit;
@implementation InAppReviewPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"dev.britannio.in_app_review" binaryMessenger:[registrar messenger]];
    
    InAppReviewPlugin* instance = [[InAppReviewPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    
    [self logMessage:@"handle" details:call.method];
    
    if ([call.method isEqual:@"requestReview"]) {
        [self requestReview:result];
    } else if ([call.method isEqual:@"isAvailable"]) {
        [self isAvailable:result];
    } else if ([call.method isEqual:@"openStoreListing"]) {
        [self openStoreListingWithStoreId:call.arguments result:result];
    } else {
        [self logMessage:@"method not implemented"];
        result(FlutterMethodNotImplemented);
    }
}

- (void) requestReview:(FlutterResult)result {
    if (@available(iOS 14, *)) {
        [self logMessage:@"iOS 14+"];
        UIWindowScene *scene = [self findActiveScene];
        [SKStoreReviewController requestReviewInScene:scene];
        result(nil);
    } else if (@available(iOS 10.3, *)) {
        [self logMessage:@"iOS 10.3+"];
        [SKStoreReviewController requestReview];
        result(nil);
    } else {
        result([FlutterError errorWithCode:@"unavailable"
                                   message:@"In-App Review unavailable"
                                   details:nil]);
    }
}

- (UIWindowScene *) findActiveScene  API_AVAILABLE(ios(13.0)){
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return scene;
        }
        
    }
    
    return nil;
}

- (void) isAvailable:(FlutterResult)result {
    if (@available(iOS 10.3, *)) {
        [self logMessage:@"available"];
        result(@YES);
    } else {
        [self logMessage:@"unavailable"];
        result(@NO);
    }
}

- (void) openStoreListingWithStoreId:(NSString *)storeId result:(FlutterResult)result {
    
    if (!storeId) {
        result([FlutterError errorWithCode:@"no-store-id"
                                   message:@"Your store id must be passed as the method channel's argument"
                                   details:nil]);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", storeId]];
    
    if (!url) {
        result([FlutterError errorWithCode:@"url-construct-fail"
                                   message:@"Failed to construct url"
                                   details:nil]);
        return;
    }
        
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [app openURL:url options:@{} completionHandler:nil];
    } else {
        [app openURL:url];
    }
}


#pragma mark - Logging Helpers

- (void) logMessage:(NSString *) message {
    NSLog(@"InAppReviewPlugin: %@", message);
}

- (void) logMessage:(NSString *) message
            details:(NSString *) details {
    NSLog(@"InAppReviewPlugin: %@ %@", message, details);
}

@end
