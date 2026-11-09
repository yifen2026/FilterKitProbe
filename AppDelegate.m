#import "AppDelegate.h"
#import "FKPProfileCollectorViewController.h"
#import "FKPEntitlementsViewController.h"
#import "FKPElleKitScannerViewController.h"
#import "FKPPListParserViewController.h"
#import "FKPAppListViewController.h"
#import "FKPDyldImagesViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    // 第一个 tab：信息采集（主页面）
    FKPProfileCollectorViewController *collectorVC = [[FKPProfileCollectorViewController alloc] init];
    UINavigationController *nav0 = [[UINavigationController alloc] initWithRootViewController:collectorVC];
    nav0.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Profile" image:nil tag:0];
    
    // 详细调试页面
    FKPEntitlementsViewController *entitlementsVC = [[FKPEntitlementsViewController alloc] init];
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:entitlementsVC];
    nav1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Entitlements" image:nil tag:1];
    
    FKPElleKitScannerViewController *ellekitVC = [[FKPElleKitScannerViewController alloc] init];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:ellekitVC];
    nav2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"ElleKit" image:nil tag:2];
    
    FKPAppListViewController *appListVC = [[FKPAppListViewController alloc] init];
    UINavigationController *nav3 = [[UINavigationController alloc] initWithRootViewController:appListVC];
    nav3.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"AppList" image:nil tag:3];
    
    FKPDyldImagesViewController *dyldVC = [[FKPDyldImagesViewController alloc] init];
    UINavigationController *nav4 = [[UINavigationController alloc] initWithRootViewController:dyldVC];
    nav4.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"dyld" image:nil tag:4];
    
    tabBarController.viewControllers = @[nav0, nav1, nav2, nav3, nav4];
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
