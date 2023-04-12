package dev.britannio.in_app_review;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;


import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * InAppReviewPlugin
 */
public class InAppReviewPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private Context context;
    private Activity activity;

    private ReviewInfo reviewInfo;

    private final String TAG = "InAppReviewPlugin";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "dev.britannio.in_app_review");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.i(TAG, "onMethodCall: " + call.method);
        switch (call.method) {
            case "isAvailable":
            case "requestReview":
            case "openStoreListing":
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        context = null;
    }

    private void isAvailable(final Result result) {
        return;
    }

    private void cacheReviewInfo(final Result result) {
        return;
    }

    private void requestReview(final Result result) {
        return;
    }

    private void launchReviewFlow(final Result result, ReviewManager manager, ReviewInfo reviewInfo) {
        return;
    }

    private boolean isPlayStoreInstalled() {
        return false;
    }


    private void openStoreListing(Result result) {
        return;
    }

    private boolean noContextOrActivity() {
        Log.i(TAG, "noContextOrActivity: called");
        if (context == null) {
            Log.e(TAG, "noContextOrActivity: Android context not available");
            return true;
        } else if (activity == null) {
            Log.e(TAG, "noContextOrActivity: Android activity not available");
            return true;
        } else {
            return false;
        }
    }

    private boolean noContextOrActivity(Result result) {
        Log.i(TAG, "noContextOrActivity: called");
        if (context == null) {
            Log.e(TAG, "noContextOrActivity: Android context not available");
            result.error("error", "Android context not available", null);
            return true;
        } else if (activity == null) {
            Log.e(TAG, "noContextOrActivity: Android activity not available");
            result.error("error", "Android activity not available", null);
            return true;
        } else {
            return false;
        }
    }

}
