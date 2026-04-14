#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

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

#pragma mark - Gyroscope / Motion sensor blocking
// 广告 SDK 常通过 CoreMotion (陀螺仪/加速度计/设备运动) 检测摇一摇
// 或倾斜手势来跳转至第三方 App / App Store。这里把相关入口统一拦截，
// 让广告页面无法读取到任何运动数据，从根源上阻止跳转。

static void EnsureCoreMotionLoaded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dlopen("/System/Library/Frameworks/CoreMotion.framework/CoreMotion", RTLD_LAZY);
    });
}

// --- CMMotionManager 启动相关方法全部变成 no-op ---

static void (*orig_startGyroUpdates)(id, SEL);
static void hook_startGyroUpdates(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_startGyroUpdatesToQueue)(id, SEL, id, id);
static void hook_startGyroUpdatesToQueue(id self, SEL _cmd, id queue, id handler) {
    (void)self;
    (void)_cmd;
    (void)queue;
    (void)handler;
}

static void (*orig_startDeviceMotionUpdates)(id, SEL);
static void hook_startDeviceMotionUpdates(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_startDeviceMotionUpdatesToQueue)(id, SEL, id, id);
static void hook_startDeviceMotionUpdatesToQueue(id self, SEL _cmd, id queue, id handler) {
    (void)self;
    (void)_cmd;
    (void)queue;
    (void)handler;
}

static void (*orig_startDeviceMotionUpdatesUsingReferenceFrame)(id, SEL, NSUInteger);
static void hook_startDeviceMotionUpdatesUsingReferenceFrame(id self, SEL _cmd, NSUInteger frame) {
    (void)self;
    (void)_cmd;
    (void)frame;
}

static void (*orig_startDeviceMotionUpdatesUsingReferenceFrameToQueue)(id, SEL, NSUInteger, id, id);
static void hook_startDeviceMotionUpdatesUsingReferenceFrameToQueue(id self, SEL _cmd,
                                                                    NSUInteger frame,
                                                                    id queue, id handler) {
    (void)self;
    (void)_cmd;
    (void)frame;
    (void)queue;
    (void)handler;
}

static void (*orig_startAccelerometerUpdates)(id, SEL);
static void hook_startAccelerometerUpdates(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_startAccelerometerUpdatesToQueue)(id, SEL, id, id);
static void hook_startAccelerometerUpdatesToQueue(id self, SEL _cmd, id queue, id handler) {
    (void)self;
    (void)_cmd;
    (void)queue;
    (void)handler;
}

static void (*orig_startMagnetometerUpdates)(id, SEL);
static void hook_startMagnetometerUpdates(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
}

static void (*orig_startMagnetometerUpdatesToQueue)(id, SEL, id, id);
static void hook_startMagnetometerUpdatesToQueue(id self, SEL _cmd, id queue, id handler) {
    (void)self;
    (void)_cmd;
    (void)queue;
    (void)handler;
}

// --- 可用性/激活状态统一返回 NO，让广告 SDK 以为设备没有陀螺仪 ---

static BOOL (*orig_isGyroAvailable)(id, SEL);
static BOOL hook_isGyroAvailable(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isGyroActive)(id, SEL);
static BOOL hook_isGyroActive(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isDeviceMotionAvailable)(id, SEL);
static BOOL hook_isDeviceMotionAvailable(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isDeviceMotionActive)(id, SEL);
static BOOL hook_isDeviceMotionActive(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isAccelerometerAvailable)(id, SEL);
static BOOL hook_isAccelerometerAvailable(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isAccelerometerActive)(id, SEL);
static BOOL hook_isAccelerometerActive(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isMagnetometerAvailable)(id, SEL);
static BOOL hook_isMagnetometerAvailable(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

static BOOL (*orig_isMagnetometerActive)(id, SEL);
static BOOL hook_isMagnetometerActive(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return NO;
}

// --- 数据属性一律返回 nil，防止轮询读取 ---

static id (*orig_gyroData)(id, SEL);
static id hook_gyroData(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return nil;
}

static id (*orig_deviceMotion)(id, SEL);
static id hook_deviceMotion(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return nil;
}

static id (*orig_accelerometerData)(id, SEL);
static id hook_accelerometerData(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return nil;
}

static id (*orig_magnetometerData)(id, SEL);
static id hook_magnetometerData(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return nil;
}

// --- 兼容老版本广告 SDK：UIAccelerometer (iOS 5 起废弃，但仍有 SDK 使用) ---

static void (*orig_setDelegate_UIAccel)(id, SEL, id);
static void hook_setDelegate_UIAccel(id self, SEL _cmd, id delegate) {
    (void)self;
    (void)_cmd;
    (void)delegate;
}

static void (*orig_setUpdateInterval_UIAccel)(id, SEL, NSTimeInterval);
static void hook_setUpdateInterval_UIAccel(id self, SEL _cmd, NSTimeInterval interval) {
    (void)self;
    (void)_cmd;
    (void)interval;
}

// --- 兜底：直接吞掉 UIResponder 系的摇一摇事件 ---

static void (*orig_motionBegan)(id, SEL, UIEventSubtype, UIEvent *);
static void hook_motionBegan(id self, SEL _cmd, UIEventSubtype motion, UIEvent *event) {
    (void)self;
    (void)_cmd;
    (void)event;
    if (motion == UIEventSubtypeMotionShake) {
        return;
    }
    if (orig_motionBegan) {
        orig_motionBegan(self, _cmd, motion, event);
    }
}

static void (*orig_motionEnded)(id, SEL, UIEventSubtype, UIEvent *);
static void hook_motionEnded(id self, SEL _cmd, UIEventSubtype motion, UIEvent *event) {
    (void)self;
    (void)_cmd;
    (void)event;
    if (motion == UIEventSubtypeMotionShake) {
        return;
    }
    if (orig_motionEnded) {
        orig_motionEnded(self, _cmd, motion, event);
    }
}

static void (*orig_motionCancelled)(id, SEL, UIEventSubtype, UIEvent *);
static void hook_motionCancelled(id self, SEL _cmd, UIEventSubtype motion, UIEvent *event) {
    (void)self;
    (void)_cmd;
    (void)event;
    if (motion == UIEventSubtypeMotionShake) {
        return;
    }
    if (orig_motionCancelled) {
        orig_motionCancelled(self, _cmd, motion, event);
    }
}

static void InstallGyroscopeBlocking(void) {
    EnsureCoreMotionLoaded();

    // CMMotionManager 启动方法
    HookInstanceMethod("CMMotionManager",
                       @selector(startGyroUpdates),
                       (IMP)hook_startGyroUpdates,
                       (IMP *)&orig_startGyroUpdates);
    HookInstanceMethod("CMMotionManager",
                       @selector(startGyroUpdatesToQueue:withHandler:),
                       (IMP)hook_startGyroUpdatesToQueue,
                       (IMP *)&orig_startGyroUpdatesToQueue);

    HookInstanceMethod("CMMotionManager",
                       @selector(startDeviceMotionUpdates),
                       (IMP)hook_startDeviceMotionUpdates,
                       (IMP *)&orig_startDeviceMotionUpdates);
    HookInstanceMethod("CMMotionManager",
                       @selector(startDeviceMotionUpdatesToQueue:withHandler:),
                       (IMP)hook_startDeviceMotionUpdatesToQueue,
                       (IMP *)&orig_startDeviceMotionUpdatesToQueue);
    HookInstanceMethod("CMMotionManager",
                       @selector(startDeviceMotionUpdatesUsingReferenceFrame:),
                       (IMP)hook_startDeviceMotionUpdatesUsingReferenceFrame,
                       (IMP *)&orig_startDeviceMotionUpdatesUsingReferenceFrame);
    HookInstanceMethod("CMMotionManager",
                       @selector(startDeviceMotionUpdatesUsingReferenceFrame:toQueue:withHandler:),
                       (IMP)hook_startDeviceMotionUpdatesUsingReferenceFrameToQueue,
                       (IMP *)&orig_startDeviceMotionUpdatesUsingReferenceFrameToQueue);

    HookInstanceMethod("CMMotionManager",
                       @selector(startAccelerometerUpdates),
                       (IMP)hook_startAccelerometerUpdates,
                       (IMP *)&orig_startAccelerometerUpdates);
    HookInstanceMethod("CMMotionManager",
                       @selector(startAccelerometerUpdatesToQueue:withHandler:),
                       (IMP)hook_startAccelerometerUpdatesToQueue,
                       (IMP *)&orig_startAccelerometerUpdatesToQueue);

    HookInstanceMethod("CMMotionManager",
                       @selector(startMagnetometerUpdates),
                       (IMP)hook_startMagnetometerUpdates,
                       (IMP *)&orig_startMagnetometerUpdates);
    HookInstanceMethod("CMMotionManager",
                       @selector(startMagnetometerUpdatesToQueue:withHandler:),
                       (IMP)hook_startMagnetometerUpdatesToQueue,
                       (IMP *)&orig_startMagnetometerUpdatesToQueue);

    // CMMotionManager 可用性 / 激活状态
    HookInstanceMethod("CMMotionManager",
                       @selector(isGyroAvailable),
                       (IMP)hook_isGyroAvailable,
                       (IMP *)&orig_isGyroAvailable);
    HookInstanceMethod("CMMotionManager",
                       @selector(isGyroActive),
                       (IMP)hook_isGyroActive,
                       (IMP *)&orig_isGyroActive);
    HookInstanceMethod("CMMotionManager",
                       @selector(isDeviceMotionAvailable),
                       (IMP)hook_isDeviceMotionAvailable,
                       (IMP *)&orig_isDeviceMotionAvailable);
    HookInstanceMethod("CMMotionManager",
                       @selector(isDeviceMotionActive),
                       (IMP)hook_isDeviceMotionActive,
                       (IMP *)&orig_isDeviceMotionActive);
    HookInstanceMethod("CMMotionManager",
                       @selector(isAccelerometerAvailable),
                       (IMP)hook_isAccelerometerAvailable,
                       (IMP *)&orig_isAccelerometerAvailable);
    HookInstanceMethod("CMMotionManager",
                       @selector(isAccelerometerActive),
                       (IMP)hook_isAccelerometerActive,
                       (IMP *)&orig_isAccelerometerActive);
    HookInstanceMethod("CMMotionManager",
                       @selector(isMagnetometerAvailable),
                       (IMP)hook_isMagnetometerAvailable,
                       (IMP *)&orig_isMagnetometerAvailable);
    HookInstanceMethod("CMMotionManager",
                       @selector(isMagnetometerActive),
                       (IMP)hook_isMagnetometerActive,
                       (IMP *)&orig_isMagnetometerActive);

    // CMMotionManager 数据属性
    HookInstanceMethod("CMMotionManager",
                       @selector(gyroData),
                       (IMP)hook_gyroData,
                       (IMP *)&orig_gyroData);
    HookInstanceMethod("CMMotionManager",
                       @selector(deviceMotion),
                       (IMP)hook_deviceMotion,
                       (IMP *)&orig_deviceMotion);
    HookInstanceMethod("CMMotionManager",
                       @selector(accelerometerData),
                       (IMP)hook_accelerometerData,
                       (IMP *)&orig_accelerometerData);
    HookInstanceMethod("CMMotionManager",
                       @selector(magnetometerData),
                       (IMP)hook_magnetometerData,
                       (IMP *)&orig_magnetometerData);

    // 废弃但仍然偶见的 UIAccelerometer
    HookInstanceMethod("UIAccelerometer",
                       @selector(setDelegate:),
                       (IMP)hook_setDelegate_UIAccel,
                       (IMP *)&orig_setDelegate_UIAccel);
    HookInstanceMethod("UIAccelerometer",
                       @selector(setUpdateInterval:),
                       (IMP)hook_setUpdateInterval_UIAccel,
                       (IMP *)&orig_setUpdateInterval_UIAccel);

    // 兜底：UIResponder 的摇一摇事件
    HookInstanceMethod("UIResponder",
                       @selector(motionBegan:withEvent:),
                       (IMP)hook_motionBegan,
                       (IMP *)&orig_motionBegan);
    HookInstanceMethod("UIResponder",
                       @selector(motionEnded:withEvent:),
                       (IMP)hook_motionEnded,
                       (IMP *)&orig_motionEnded);
    HookInstanceMethod("UIResponder",
                       @selector(motionCancelled:withEvent:),
                       (IMP)hook_motionCancelled,
                       (IMP *)&orig_motionCancelled);
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

        InstallGyroscopeBlocking();

        NSLog(@"[NoAd] hooks installed");
    });
}
