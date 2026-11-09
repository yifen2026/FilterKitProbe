#import "FKPElleKitScannerViewController.h"
#import <sys/stat.h>
#import <sys/syslimits.h>
#import <mach-o/dyld.h>

@implementation FKPElleKitScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ElleKit 插件目录扫描";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:11];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 先反推 jbroot 根目录
    [result appendString:@"=== 反推 jbroot 根目录 ===\n\n"];
    
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    NSString *execPath = nil;
    NSString *jbrootPath = nil;
    
    if (_NSGetExecutablePath(path, &size) == 0) {
        execPath = [NSString stringWithUTF8String:path];
        [result appendFormat:@"可执行文件: %@\n", execPath];
        
        NSRange range = [execPath rangeOfString:@".jbroot-"];
        if (range.location != NSNotFound) {
            NSRange slashRange = [execPath rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
            if (slashRange.location != NSNotFound) {
                NSRange endRange = [execPath rangeOfString:@"/" options:0 range:NSMakeRange(range.location + range.length, execPath.length - range.location - range.length)];
                if (endRange.location != NSNotFound) {
                    jbrootPath = [execPath substringToIndex:endRange.location];
                    [result appendFormat:@"jbroot 根: %@\n\n", jbrootPath];
                }
            }
        }
    }
    
    // 基于 jbroot 路径测试插件目录
    if (jbrootPath) {
        [result appendString:@"=== 基于 jbroot 的插件目录 ===\n\n"];
        
        NSArray *candidateDirs = @[
            @"Library/MobileSubstrate/DynamicLibraries",
            @"usr/lib/TweakInject",
            @"Library/TweakInject"
        ];
        
        for (NSString *relativePath in candidateDirs) {
            NSString *fullPath = [jbrootPath stringByAppendingPathComponent:relativePath];
            struct stat st;
            BOOL exists = (stat([fullPath UTF8String], &st) == 0);
            
            [result appendFormat:@"路径: %@\n", relativePath];
            [result appendFormat:@"  完整路径: %@\n", fullPath];
            [result appendFormat:@"  存在: %@\n", exists ? @"是" : @"否"];
            
            if (exists) {
                BOOL isSymlink = (S_ISLNK(st.st_mode));
                [result appendFormat:@"  是符号链接: %@\n", isSymlink ? @"是" : @"否"];
                
                if (isSymlink) {
                    char resolvedPath[PATH_MAX];
                    if (realpath([fullPath UTF8String], resolvedPath) != NULL) {
                        [result appendFormat:@"  实际指向: %s\n", resolvedPath];
                    }
                }
                
                [result appendFormat:@"  权限: %o\n", st.st_mode & 0777];
                
                // 列出目录内容
                NSError *error = nil;
                NSArray *contents = [fm contentsOfDirectoryAtPath:fullPath error:&error];
                if (error) {
                    [result appendFormat:@"  读取错误: %@\n", error.localizedDescription];
                } else {
                    [result appendFormat:@"  文件数量: %lu\n", (unsigned long)contents.count];
                    
                    int dylibCount = 0;
                    int plistCount = 0;
                    NSMutableArray *dylibNames = [NSMutableArray array];
                    
                    for (NSString *file in contents) {
                        if ([[file pathExtension] isEqualToString:@"dylib"]) {
                            dylibCount++;
                            [dylibNames addObject:file];
                        } else if ([[file pathExtension] isEqualToString:@"plist"]) {
                            plistCount++;
                        }
                    }
                    
                    [result appendFormat:@"  dylib 数量: %d\n", dylibCount];
                    [result appendFormat:@"  plist 数量: %d\n", plistCount];
                    
                    if (dylibCount > 0 && dylibCount <= 20) {
                        [result appendString:@"  dylib 列表:\n"];
                        for (NSString *name in dylibNames) {
                            [result appendFormat:@"    - %@\n", name];
                        }
                    }
                }
            }
            
            [result appendString:@"\n"];
        }
    }
    
    // 标准路径测试
    [result appendString:@"=== 标准路径测试 ===\n\n"];
    
    NSArray *standardDirs = @[
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/var/jb/Library/MobileSubstrate/DynamicLibraries",
        @"/usr/lib/TweakInject"
    ];
    
    for (NSString *dir in standardDirs) {
        BOOL exists = [fm fileExistsAtPath:dir];
        [result appendFormat:@"%@: %@\n", dir, exists ? @"存在" : @"不存在"];
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
