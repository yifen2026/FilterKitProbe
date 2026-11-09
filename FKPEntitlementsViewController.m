#import "FKPEntitlementsViewController.h"
#import <sys/sysctl.h>
#import <unistd.h>
#import <mach-o/dyld.h>

@implementation FKPEntitlementsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Entitlements 验证";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:11];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 基本进程信息
    [result appendString:@"=== 进程基本信息 ===\n"];
    [result appendFormat:@"PID: %d\n", getpid()];
    [result appendFormat:@"UID: %d\n", getuid()];
    [result appendFormat:@"EUID: %d\n", geteuid()];
    [result appendFormat:@"GID: %d\n", getgid()];
    [result appendFormat:@"EGID: %d\n", getegid()];
    
    // 可执行文件路径
    [result appendString:@"\n=== 可执行文件路径 ===\n"];
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    NSString *execPath = nil;
    if (_NSGetExecutablePath(path, &size) == 0) {
        execPath = [NSString stringWithUTF8String:path];
        [result appendFormat:@"路径: %@\n", execPath];
    }
    
    // 从可执行文件路径反推 jbroot 根目录
    [result appendString:@"\n=== 反推 jbroot 根目录 ===\n"];
    NSString *jbrootPath = nil;
    if (execPath) {
        NSRange range = [execPath rangeOfString:@".jbroot-"];
        if (range.location != NSNotFound) {
            // 找到 .jbroot- 的位置，往前找到 /
            NSRange slashRange = [execPath rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            if (slashRange.location != NSNotFound) {
                // 从 / 开始，到 .jbroot-XXXXXX 结束
                NSRange endRange = [execPath rangeOfString:@"/" options:0 range:NSMakeRange(range.location + range.length, execPath.length - range.location - range.length)];
                if (endRange.location != NSNotFound) {
                    jbrootPath = [execPath substringToIndex:endRange.location];
                    [result appendFormat:@"反推结果: %@\n", jbrootPath];
                    
                    // 验证这个路径
                    BOOL isDir;
                    BOOL exists = [fm fileExistsAtPath:jbrootPath isDirectory:&isDir];
                    [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
                    if (exists) {
                        [result appendFormat:@"  是目录: %@\n", isDir ? @"是" : @"否"];
                        [result appendFormat:@"  可读: %@\n", [fm isReadableFileAtPath:jbrootPath] ? @"是" : @"否"];
                        [result appendFormat:@"  可写: %@\n", [fm isWritableFileAtPath:jbrootPath] ? @"是" : @"否"];
                    }
                }
            }
        }
    }
    
    // 基于 jbroot 根目录测试关键路径
    if (jbrootPath) {
        [result appendString:@"\n=== 基于 jbroot 测试关键目录 ===\n"];
        
        NSArray *testPaths = @[
            @"Library/MobileSubstrate/DynamicLibraries",
            @"usr/lib/TweakInject",
            @"Library/LaunchDaemons",
            @"var/mobile/Library",
            @"var/mobile/Library/Preferences",
            @"usr/bin",
            @"Library/Frameworks"
        ];
        
        for (NSString *relativePath in testPaths) {
            NSString *fullPath = [jbrootPath stringByAppendingPathComponent:relativePath];
            BOOL isDir;
            BOOL exists = [fm fileExistsAtPath:fullPath isDirectory:&isDir];
            
            [result appendFormat:@"%@\n", relativePath];
            [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
            if (exists) {
                [result appendFormat:@"  可读: %@\n", [fm isReadableFileAtPath:fullPath] ? @"是" : @"否"];
                [result appendFormat:@"  可写: %@\n", [fm isWritableFileAtPath:fullPath] ? @"是" : @"否"];
            }
        }
    }
    
    // 测试标准路径
    [result appendString:@"\n=== 标准路径测试 ===\n"];
    NSArray *standardPaths = @[
        @"/var/mobile",
        @"/var/containers/Bundle/Application",
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/var/jb/Library/MobileSubstrate/DynamicLibraries",
        @"/var/run"
    ];
    
    for (NSString *testPath in standardPaths) {
        BOOL isDir;
        BOOL exists = [fm fileExistsAtPath:testPath isDirectory:&isDir];
        [result appendFormat:@"%@: %@\n", testPath, exists ? @"存在" : @"不存在"];
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
