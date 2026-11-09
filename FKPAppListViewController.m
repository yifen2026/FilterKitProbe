#import "FKPAppListViewController.h"
#import <mach-o/dyld.h>

@implementation FKPAppListViewController

- (void)appendPlist:(NSDictionary *)plist toResult:(NSMutableString *)result indent:(NSString *)indent {
    for (NSString *key in plist.allKeys) {
        id value = plist[key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            [result appendFormat:@"%@%@:\n", indent, key];
            [self appendPlist:value toResult:result indent:[indent stringByAppendingString:@"  "]];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [result appendFormat:@"%@%@: 数组 (%lu 项)\n", indent, key, (unsigned long)[(NSArray *)value count]];
            NSArray *array = (NSArray *)value;
            for (NSUInteger i = 0; i < array.count && i < 20; i++) {
                id item = array[i];
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [result appendFormat:@"%@  [%lu]: 字典\n", indent, (unsigned long)i];
                    [self appendPlist:item toResult:result indent:[indent stringByAppendingString:@"    "]];
                } else {
                    [result appendFormat:@"%@  [%lu]: %@\n", indent, (unsigned long)i, item];
                }
            }
            if (array.count > 20) {
                [result appendFormat:@"%@  ... 还有 %lu 项\n", indent, (unsigned long)(array.count - 20)];
            }
        } else if ([value isKindOfClass:[NSString class]]) {
            [result appendFormat:@"%@%@: %@\n", indent, key, value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [result appendFormat:@"%@%@: %@\n", indent, key, value];
        } else {
            [result appendFormat:@"%@%@: %@\n", indent, key, [value class]];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"RootHide App List";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:10];
    textView.editable = NO;
    
    NSMutableString *result = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 反推 jbroot 根目录
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
    
    if (jbrootPath) {
        // 详细解析 RootHide 目录
        NSString *rootHideDir = [jbrootPath stringByAppendingPathComponent:@"var/mobile/Library/RootHide"];
        [result appendString:@"========================================\n"];
        [result appendString:@"=== RootHideConfig.plist 完整内容 ===\n"];
        [result appendString:@"========================================\n\n"];
        
        NSString *configPath = [rootHideDir stringByAppendingPathComponent:@"RootHideConfig.plist"];
        BOOL configExists = [fm fileExistsAtPath:configPath];
        [result appendFormat:@"路径: %@\n", configPath];
        [result appendFormat:@"存在: %@\n\n", configExists ? @"是" : @"否"];
        
        if (configExists) {
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:configPath];
            if (plist) {
                [self appendPlist:plist toResult:result indent:@""];
            } else {
                [result appendString:@"解析失败\n"];
            }
        }
        
        // 解析 varCleanRules.plist
        [result appendString:@"\n========================================\n"];
        [result appendString:@"=== varCleanRules.plist ===\n"];
        [result appendString:@"========================================\n\n"];
        
        NSString *cleanRulesPath = [rootHideDir stringByAppendingPathComponent:@"varCleanRules.plist"];
        BOOL cleanRulesExists = [fm fileExistsAtPath:cleanRulesPath];
        [result appendFormat:@"存在: %@\n\n", cleanRulesExists ? @"是" : @"否"];
        
        if (cleanRulesExists) {
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:cleanRulesPath];
            if (plist) {
                [self appendPlist:plist toResult:result indent:@""];
            }
        }
        
        // 解析 varCleanRules-custom.plist
        [result appendString:@"\n========================================\n"];
        [result appendString:@"=== varCleanRules-custom.plist ===\n"];
        [result appendString:@"========================================\n\n"];
        
        NSString *customPath = [rootHideDir stringByAppendingPathComponent:@"varCleanRules-custom.plist"];
        BOOL customExists = [fm fileExistsAtPath:customPath];
        [result appendFormat:@"存在: %@\n\n", customExists ? @"是" : @"否"];
        
        if (customExists) {
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:customPath];
            if (plist) {
                [self appendPlist:plist toResult:result indent:@""];
            }
        }
        
        // Preferences 目录里的其他 plist
        [result appendString:@"\n========================================\n"];
        [result appendString:@"=== Preferences 目录其他 plist ===\n"];
        [result appendString:@"========================================\n\n"];
        
        NSString *prefsDir = [jbrootPath stringByAppendingPathComponent:@"var/mobile/Library/Preferences"];
        NSArray *prefs = [fm contentsOfDirectoryAtPath:prefsDir error:nil];
        
        for (NSString *pref in prefs) {
            if ([pref containsString:@"roothide"] || [pref containsString:@"ellekit"] || [pref containsString:@"jail"]) {
                NSString *prefPath = [prefsDir stringByAppendingPathComponent:pref];
                [result appendFormat:@"--- %@ ---\n", pref];
                NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:prefPath];
                if (plist) {
                    [self appendPlist:plist toResult:result indent:@"  "];
                } else {
                    [result appendString:@"  解析失败\n"];
                }
                [result appendString:@"\n"];
            }
        }
    }
    
    textView.text = result;
    [self.view addSubview:textView];
}

@end
