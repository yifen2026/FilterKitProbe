#import "FKPDyldImagesViewController.h"
#import <mach-o/dyld.h>

@implementation FKPDyldImagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"dyld 镜像列表";
    self.view.backgroundColor = [UIColor blackColor];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont systemFontOfSize:10];
    textView.editable = NO;
    [self.view addSubview:textView];
    
    NSMutableString *result = [NSMutableString string];
    
    // 统计
    NSInteger count = _dyld_image_count();
    NSInteger jbrootCount = 0;
    NSInteger systemCount = 0;
    
    [result appendFormat:@"=== dyld 镜像统计 ===\n\n"];
    [result appendFormat:@"总镜像数: %ld\n", (long)count];
    [result appendString:@"\n"];
    
    // 遍历所有镜像
    NSMutableArray *jbrootImages = [NSMutableArray array];
    NSMutableArray *otherImages = [NSMutableArray array];
    
    for (NSInteger i = 0; i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!imageName) continue;
        
        NSString *name = [NSString stringWithUTF8String:imageName];
        
        if ([name containsString:@".jbroot-"]) {
            jbrootCount++;
            [jbrootImages addObject:name];
        } else if ([name hasPrefix:@"/System/Library"] || [name hasPrefix:@"/usr/lib"]) {
            systemCount++;
        } else {
            [otherImages addObject:name];
        }
    }
    
    [result appendFormat:@"系统镜像: %ld\n", (long)systemCount];
    [result appendFormat:@"jbroot 镜像: %ld\n", (long)jbrootCount];
    [result appendFormat:@"其他镜像: %ld\n", (long)otherImages.count];
    [result appendString:@"\n"];
    
    // 显示 jbroot 镜像（重点）
    [result appendString:@"========================================\n"];
    [result appendString:@"=== jbroot 下的镜像（插件） ===\n"];
    [result appendString:@"========================================\n\n"];
    
    if (jbrootImages.count == 0) {
        [result appendString:@"没有 jbroot 镜像（插件未注入）\n\n"];
    } else {
        for (NSString *name in jbrootImages) {
            [result appendFormat:@"  - %@\n", name.lastPathComponent];
            [result appendFormat:@"    路径: %@\n", name];
        }
        [result appendString:@"\n"];
    }
    
    // 显示其他非系统镜像
    [result appendString:@"========================================\n"];
    [result appendString:@"=== 其他非系统镜像 ===\n"];
    [result appendString:@"========================================\n\n"];
    
    for (NSString *name in otherImages) {
        [result appendFormat:@"  - %@\n", name.lastPathComponent];
    }
    
    textView.text = result;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;
    
    for (UIView *subview in self.view.subviews) {
        subview.frame = CGRectMake(0, top, self.view.bounds.size.width, self.view.bounds.size.height - top - bottom);
    }
}

@end
