#import "FKPProfileCollectorViewController.h"
#import <sys/utsname.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

@interface FKPProfileCollectorViewController ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSDictionary *profile;
@end

@implementation FKPProfileCollectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"信息采集";
    self.view.backgroundColor = [UIColor blackColor];
    
    // 文本视图
    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = [UIColor blackColor];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.font = [UIFont systemFontOfSize:11];
    self.textView.editable = NO;
    self.textView.text = @"点击右上角按钮开始采集";
    [self.view addSubview:self.textView];
    
    // 采集按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"采集" style:UIBarButtonItemStyleDone target:self action:@selector(startCollect)];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;
    CGFloat width = self.view.bounds.size.width;
    
    self.textView.frame = CGRectMake(0, top, width, self.view.bounds.size.height - top - bottom);
}

- (void)startCollect {
    self.textView.text = @"正在采集...";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *profile = [self collectAllInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profile = profile;
            
            // 生成 JSON 字符串
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:profile options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            self.textView.text = jsonString;
        });
    });
}

- (NSDictionary *)collectAllInfo {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    // 1. 环境信息
    result[@"environment"] = [self collectEnvironment];
    
    // 2. RootHide 信息
    result[@"roothide"] = [self collectRootHide];
    
    // 3. 安全信息
    result[@"security"] = [self collectSecurity];
    
    // 4. ElleKit 信息
    result[@"ellekit"] = [self collectElleKit];
    
    // 5. Bootstrap 信息
    result[@"bootstrap"] = [self collectBootstrap];
    
    // 6. 插件管理
    result[@"plugin_management"] = [self collectPluginManagement];
    
    // 7. 运行时信息
    result[@"runtime"] = [self collectRuntime];
    
    // 未验证项
    result[@"unverified"] = @[
        @"theos_compile_env",
        @"daemon_process_info",
        @"ipc_socket_path"
    ];
    
    return result;
}

#pragma mark - 环境信息

- (NSDictionary *)collectEnvironment {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // 系统版本
    dict[@"ios_version"] = [[UIDevice currentDevice] systemVersion];
    
    // Build 号
    dict[@"ios_build"] = [self iosBuildVersion];
    
    // 设备型号
    dict[@"device_model"] = [self deviceModel];
    
    // CPU 架构
    dict[@"cpu_arch"] = [self cpuArch];
    
    // 越狱类型
    dict[@"jailbreak_type"] = @"roothide_rootless";
    
    return dict;
}

- (NSString *)iosBuildVersion {
    NSDictionary *systemInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    return systemInfo[@"ProductBuildVersion"] ?: @"UNKNOWN";
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

- (NSString *)cpuArch {
    NSString *arch = @"arm64";
    #if defined(__arm64e__)
        arch = @"arm64e";
    #elif defined(__arm64__)
        arch = @"arm64";
    #endif
    return arch;
}

#pragma mark - RootHide 信息

- (NSDictionary *)collectRootHide {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // 从可执行文件反推 jbroot 路径
    NSString *execPath = [self executablePath];
    dict[@"executable_path"] = execPath;
    
    NSString *jbroot = [self jbrootFromExecPath:execPath];
    dict[@"jbroot_path"] = jbroot;
    dict[@"jbroot_exists"] = @([[NSFileManager defaultManager] fileExistsAtPath:jbroot]);
    
    // 测试 RootHide API（只检测符号是否存在，不调用！）
    dict[@"api_jbroot"] = [self testFunction:@"jbroot"];
    dict[@"api_rootfs"] = [self testFunction:@"rootfs"];
    dict[@"api_jbrand"] = [self testFunction:@"jbrand"];
    
    // 标准路径测试
    dict[@"standard_paths"] = @{
        @"/var/jb": @([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]),
        @"/var/jb/Library/MobileSubstrate/DynamicLibraries": @([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb/Library/MobileSubstrate/DynamicLibraries"]),
        @"/Library/MobileSubstrate/DynamicLibraries": @([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries"]),
    };
    
    return dict;
}

- (NSString *)executablePath {
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) == 0) {
        return [NSString stringWithUTF8String:path];
    }
    return @"UNKNOWN";
}

- (NSString *)jbrootFromExecPath:(NSString *)execPath {
    // 格式: /var/containers/Bundle/Application/.jbroot-XXXX/Applications/App.app/App
    // 反推: 往上找 .jbroot- 开头的目录
    NSArray *components = [execPath pathComponents];
    for (NSInteger i = components.count - 1; i >= 0; i--) {
        NSString *component = components[i];
        if ([component hasPrefix:@".jbroot-"]) {
            return [NSString pathWithComponents:[components subarrayWithRange:NSMakeRange(0, i + 1)]];
        }
    }
    return nil;
}

- (id)testFunction:(NSString *)name {
    void *handle = dlopen(NULL, RTLD_NOW);
    if (!handle) return @{@"available": @(NO), @"error": @"dlopen failed"};
    
    void *symbol = dlsym(handle, [name UTF8String]);
    if (!symbol) return @{@"available": @(NO), @"error": @"symbol not found"};
    
    // 只检测符号是否存在，不调用！
    return @{@"available": @(YES), @"result": @"found but not called"};
}

#pragma mark - 安全信息

- (NSDictionary *)collectSecurity {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // 进程身份
    dict[@"process_identity"] = @{
        @"uid": @(getuid()),
        @"euid": @(geteuid()),
        @"gid": @(getgid()),
        @"egid": @(getegid()),
    };
    
    // 沙盒权限测试（基于 jbroot）
    NSString *jbroot = [self jbrootFromExecPath:[self executablePath]];
    if (jbroot) {
        NSMutableDictionary *perms = [NSMutableDictionary dictionary];
        
        NSArray *testPaths = @[
            @"Library/MobileSubstrate/DynamicLibraries",
            @"usr/lib/TweakInject",
            @"Library/LaunchDaemons",
            @"var/mobile/Library",
            @"var/mobile/Library/Preferences",
            @"usr/bin",
            @"Library/Frameworks",
        ];
        
        for (NSString *relativePath in testPaths) {
            NSString *fullPath = [jbroot stringByAppendingPathComponent:relativePath];
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
            BOOL readable = [[NSFileManager defaultManager] isReadableFileAtPath:fullPath];
            BOOL writable = [[NSFileManager defaultManager] isWritableFileAtPath:fullPath];
            
            perms[relativePath] = @{
                @"exists": @(exists),
                @"readable": @(readable),
                @"writable": @(writable),
            };
        }
        
        dict[@"jbroot_permissions"] = perms;
    }
    
    return dict;
}

#pragma mark - ElleKit 信息

- (NSDictionary *)collectElleKit {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSString *jbroot = [self jbrootFromExecPath:[self executablePath]];
    
    // 插件目录
    NSArray *pluginDirs = @[
        @"Library/MobileSubstrate/DynamicLibraries",
        @"usr/lib/TweakInject",
    ];
    
    NSMutableArray *dirs = [NSMutableArray array];
    NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
    
    for (NSString *relativeDir in pluginDirs) {
        NSString *fullDir = [jbroot stringByAppendingPathComponent:relativeDir];
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:fullDir];
        
        if (exists) {
            [dirs addObject:@{
                @"path": fullDir,
                @"exists": @(YES),
            }];
            
            // 扫描插件
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullDir error:nil];
            for (NSString *file in files) {
                if ([file hasSuffix:@".plist"]) {
                    NSString *pluginName = [file stringByDeletingPathExtension];
                    NSString *dylibPath = [fullDir stringByAppendingPathComponent:[pluginName stringByAppendingPathExtension:@"dylib"]];
                    BOOL dylibExists = [[NSFileManager defaultManager] fileExistsAtPath:dylibPath];
                    
                    // 解析 plist
                    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[fullDir stringByAppendingPathComponent:file]];
                    
                    plugins[pluginName] = @{
                        @"plist_path": [fullDir stringByAppendingPathComponent:file],
                        @"dylib_path": dylibPath,
                        @"dylib_exists": @(dylibExists),
                        @"filter": plist[@"Filter"] ?: @{},
                    };
                }
            }
        }
    }
    
    dict[@"plugin_directories"] = dirs;
    dict[@"plugins"] = plugins;
    
    return dict;
}

#pragma mark - Bootstrap 信息

- (NSDictionary *)collectBootstrap {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSString *jbroot = [self jbrootFromExecPath:[self executablePath]];
    NSString *configPath = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/RootHideConfig.plist"];
    
    dict[@"config_path"] = configPath;
    dict[@"config_exists"] = @([[NSFileManager defaultManager] fileExistsAtPath:configPath]);
    
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:configPath];
    if (config) {
        dict[@"appconfig"] = config[@"appconfig"] ?: @{};
    }
    
    // varCleanRules
    NSString *cleanRulesPath = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/RootHide/varCleanRules.plist"];
    dict[@"varCleanRules_exists"] = @([[NSFileManager defaultManager] fileExistsAtPath:cleanRulesPath]);
    
    return dict;
}

#pragma mark - 插件管理

- (NSDictionary *)collectPluginManagement {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // 安装机制
    dict[@"install"] = @{
        @"method": @"unknown",
        @"needs_daemon": @(YES),
    };
    
    // 启停机制
    dict[@"enable_disable"] = @{
        @"method": @"unknown",
        @"requires_respring": @(YES),
    };
    
    return dict;
}

#pragma mark - 运行时信息

- (NSDictionary *)collectRuntime {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // dyld 镜像统计
    NSInteger count = _dyld_image_count();
    NSInteger jbrootCount = 0;
    NSMutableArray *jbrootImages = [NSMutableArray array];
    
    for (NSInteger i = 0; i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!imageName) continue;
        
        NSString *name = [NSString stringWithUTF8String:imageName];
        if ([name containsString:@".jbroot-"]) {
            jbrootCount++;
            [jbrootImages addObject:name.lastPathComponent];
        }
    }
    
    dict[@"dyld_total_images"] = @(count);
    dict[@"dyld_jbroot_images"] = @(jbrootCount);
    dict[@"dyld_jbroot_image_names"] = jbrootImages;
    
    return dict;
}

@end
