#import "SyncedSharedPreferencesPlugin.h"
#if __has_include(<synced_shared_preferences/synced_shared_preferences-Swift.h>)
#import <synced_shared_preferences/synced_shared_preferences-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "synced_shared_preferences-Swift.h"
#endif

@implementation SyncedSharedPreferencesPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSyncedSharedPreferencesPlugin registerWithRegistrar:registrar];
}
@end
