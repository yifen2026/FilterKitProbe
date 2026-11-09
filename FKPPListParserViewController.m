#import "FKPPListParserViewController.h"
#import <mach-o/dyld.h>

@implementation FKPPListParserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"过滤 Plist 解析";
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
    NSString *jbrootPath = nil;
    
    if (_NSGetExecutablePath(path, &size) == 0) {
        NSString *execPath = [NSString stringWithUTF8String:path];
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
    
    // 收集所有可能的插件目录
    NSMutableArray *allPluginDirs = [NSMutableArray array];
    
    if (jbrootPath) {
        [allPluginDirs addObject:[jbrootPath stringByAppendingPathComponent:@"Library/MobileSubstrate/DynamicLibraries"]];
        [allPluginDirs addObject:[jbrootPath stringByAppendingPathComponent:@"usr/lib/TweakInject"]];
    }
    
    [result appendString:@"=== 找到的插件目录 ===\n"];
    for (NSString *dir in allPluginDirs) {
        BOOL exists = [fm fileExistsAtPath:dir];
        [result appendFormat:@"  %@ (%@)\n", dir, exists ? @"存在" : @"不存在"];
    }
    [result appendString:@"\n"];
    
    // 遍历每个目录，解析 plist
    for (NSString *pluginDir in allPluginDirs) {
        BOOL dirExists = [fm fileExistsAtPath:pluginDir];
        if (!dirExists) {
            [result appendFormat:@"--- %@ 不存在 ---\n\n", pluginDir];
            continue;
        }
        
        [result appendFormat:@"========================================\n"];
        [result appendFormat:@"目录: %@\n", pluginDir];
        [result appendFormat:@"========================================\n\n"];
        
        NSArray *contents = [fm contentsOfDirectoryAtPath:pluginDir error:nil];
        if (!contents) {
            [result appendString:@"  无法读取目录\n\n"];
            continue;
        }
        
        // 收集所有 plist 文件
        NSMutableArray *plistFiles = [NSMutableArray array];
        for (NSString *file in contents) {
            if ([[file pathExtension] isEqualToString:@"plist"]) {
                [plistFiles addObject:file];
            }
        }
        
        if (plistFiles.count == 0) {
            [result appendString:@"  没有找到 plist 文件\n\n"];
            continue;
        }
        
        for (NSString *plistName in plistFiles) {
            NSString *plistPath = [pluginDir stringByAppendingPathComponent:plistName];
            NSString *dylibName = [[plistName stringByDeletingPathExtension] stringByAppendingPathExtension:@"dylib"];
            NSString *dylibPath = [pluginDir stringByAppendingPathComponent:dylibName];
            
            [result appendFormat:@"--- %@ ---\n", plistName];
            [result appendFormat:@"  对应 dylib: %@ (%@)\n", dylibName, [fm fileExistsAtPath:dylibPath] ? @"存在" : @"不存在"];
            
            // 解析 plist
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            if (!plist) {
                [result appendString:@"  解析失败\n\n"];
                continue;
            }
            
            [result appendFormat:@"  顶层 keys: %@\n", plist.allKeys];
            
            // 检查 Filter 字段
            NSDictionary *filter = plist[@"Filter"];
            if (filter) {
                [result appendFormat:@"  Filter keys: %@\n", filter.allKeys];
                
                // Bundles
                NSArray *bundles = filter[@"Bundles"];
                if (bundles) {
                    [result appendFormat:@"    Bundles: %lu 个\n", (unsigned long)bundles.count];
                    for (NSString *bundle in bundles) {
                        [result appendFormat:@"      - %@\n", bundle];
                    }
                }
                
                // Executables
                NSArray *executables = filter[@"Executables"];
                if (executables) {
                    [result appendFormat:@"    Executables: %lu 个\n", (unsigned long)executables.count];
                    for (NSString *exec in executables) {
                        [result appendFormat:@"      - %@\n", exec];
                    }
                }
                
                // Classes
                NSArray *classes = filter[@"Classes"];
                if (classes) {
                    [result appendFormat:@"    Classes: %lu 个\n", (unsigned long)classes.count];
                    for (NSString *cls in classes) {
                        [result appendFormat:@"      - %@\n", cls];
                    }
                }
            } else {
                [result appendString:@"  没有 Filter 字段\n"];
            }
            
            [result appendString:@"\n"];
        }
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
