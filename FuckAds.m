#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef void (^NoAdVoidBlock)(void);

static void HookInstanceMethod(const char *className, SEL selector, IMP replacement, IMP *originalOut) {
    Class cls = objc_getClass(className);
    if (!cls) {
        NSLog(@"[NoAd] class not found: %s", className);
        return;
    }

    Method method = class_getInstanceMethod(cls, selector);
    if (!method) {
        NSLog(@"[NoAd] method not found: %s %@", className, NSStringFromSelector(selector));
        return;
    }

    IMP previous = method_getImplementation(method);
    if (originalOut != NULL) {
        *originalOut = previous;
    }
    method_setImplementation(method, replacement);
}

static id GetObjectIvarIfPresent(id object, const char *ivarName) {
    if (!object || !ivarName) {
        return nil;
    }

    Class cls = object_getClass(object);
    if (!cls) {
        return nil;
    }

    Ivar ivar = class_getInstanceVariable(cls, ivarName);
    if (!ivar) {
        return nil;
    }

    return object_getIvar(object, ivar);
}

static void DispatchCallbackIfPresent(id candidate) {
    if (!candidate) {
        return;
    }

    NSString *className = NSStringFromClass(object_getClass(candidate));
    if (![className containsString:@"Block"]) {
        return;
    }

    NoAdVoidBlock callback = candidate;
    dispatch_async(dispatch_get_main_queue(), callback);
}

static void (*orig_loadSplashAd)(id, SEL);
static void hook_loadSplashAd(id self, SEL _cmd) {
    (void)_cmd;
    DispatchCallbackIfPresent(GetObjectIvarIfPresent(self, "_adEndCallback"));
}

static void (*orig_showSplashAdAndShowAdEndCallback)(id, SEL, id);
static void hook_showSplashAdAndShowAdEndCallback(id self, SEL _cmd, id callback) {
    (void)self;
    (void)_cmd;
    DispatchCallbackIfPresent(callback);
}

static void (*orig_interstitial_loadSplashAd)(id, SEL);
static void hook_interstitial_loadSplashAd(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_showInterstitialAdWithScene)(id, SEL, NSInteger);
static void hook_showInterstitialAdWithScene(id self, SEL _cmd, NSInteger scene) {
    (void)_cmd;
    (void)scene;
    DispatchCallbackIfPresent(GetObjectIvarIfPresent(self, "_interstitiaAdCompleteCallback"));
}

static void (*orig_becomeActiveNotification)(id, SEL);
static void hook_becomeActiveNotification(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_willResignActive)(id, SEL);
static void hook_willResignActive(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static id (*orig_showSplashWithPlacementID)(id, SEL, NSString *, NSString *, UIWindow *, UIViewController *, id);
static id hook_showSplashWithPlacementID(id self, SEL _cmd,
                                         NSString *placementID, NSString *scene,
                                         UIWindow *window, UIViewController *viewController, id delegate) {
    (void)self;
    (void)_cmd;
    (void)placementID;
    (void)scene;
    (void)window;
    (void)viewController;
    (void)delegate;
    return nil;
}

static id (*orig_showInterstitialWithPlacementID)(id, SEL, NSString *, UIViewController *, id);
static id hook_showInterstitialWithPlacementID(id self, SEL _cmd,
                                               NSString *placementID,
                                               UIViewController *viewController, id delegate) {
    (void)self;
    (void)_cmd;
    (void)placementID;
    (void)viewController;
    (void)delegate;
    return nil;
}

static void (*orig_showAdFromCache)(id, SEL);
static void hook_showAdFromCache(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_showAdImmediately)(id, SEL);
static void hook_showAdImmediately(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

__attribute__((constructor))
static void NoAdInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        HookInstanceMethod("QSSplashAd",
                           @selector(loadSplashAd),
                           (IMP)hook_loadSplashAd,
                           (IMP *)&orig_loadSplashAd);
        HookInstanceMethod("QSSplashAd",
                           @selector(showSplashAdAndShowAdEndCallback:),
                           (IMP)hook_showSplashAdAndShowAdEndCallback,
                           (IMP *)&orig_showSplashAdAndShowAdEndCallback);

        HookInstanceMethod("QSInterstitiaAd",
                           @selector(loadSplashAd),
                           (IMP)hook_interstitial_loadSplashAd,
                           (IMP *)&orig_interstitial_loadSplashAd);
        HookInstanceMethod("QSInterstitiaAd",
                           @selector(showInterstitialAdWithScene:),
                           (IMP)hook_showInterstitialAdWithScene,
                           (IMP *)&orig_showInterstitialAdWithScene);

        HookInstanceMethod("YFBackgroundManager",
                           @selector(becomeActiveNotification),
                           (IMP)hook_becomeActiveNotification,
                           (IMP *)&orig_becomeActiveNotification);
        HookInstanceMethod("YFBackgroundManager",
                           @selector(willResignActive),
                           (IMP)hook_willResignActive,
                           (IMP *)&orig_willResignActive);

        HookInstanceMethod("ATSplashManager",
                           @selector(showSplashWithPlacementID:scene:window:inViewController:delegate:),
                           (IMP)hook_showSplashWithPlacementID,
                           (IMP *)&orig_showSplashWithPlacementID);
        HookInstanceMethod("ATInterstitialManager",
                           @selector(showInterstitialWithPlacementID:inViewController:delegate:),
                           (IMP)hook_showInterstitialWithPlacementID,
                           (IMP *)&orig_showInterstitialWithPlacementID);

        HookInstanceMethod("YFAdSupplierManager",
                           @selector(showAdFromCache),
                           (IMP)hook_showAdFromCache,
                           (IMP *)&orig_showAdFromCache);
        HookInstanceMethod("YFAdSupplierManager",
                           @selector(showAdImmediately),
                           (IMP)hook_showAdImmediately,
                           (IMP *)&orig_showAdImmediately);

        NSLog(@"[NoAd] hooks installed");
    });
}
