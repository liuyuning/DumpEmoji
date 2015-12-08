//
//  ViewController.m
//  DumpEmoji
//
//  Created by liuyuning on 15/10/26.
//  Copyright (c) 2015年 liuyuning. All rights reserved.
//

#import "ViewController.h"

#import "UIKeyboardEmoji.h"
#import "UIKeyboardEmojiCategory.h"


@interface ViewController ()
@property (nonatomic,strong)IBOutlet UILabel *textLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)actionDump:(UIButton *)sender{
    
    NSLog(@"Dump start!");
    
    self.textLabel.text = nil;
    [self getEmojiListFromSysKeyboard];
    
    NSLog(@"Dump finish!");
    
#if TARGET_IPHONE_SIMULATOR
    NSString *hostHome = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_HOST_HOME"];
    self.textLabel.text = [NSString stringWithFormat:@"😀Dump finish!\n Files under %@/",hostHome];
#else
    self.textLabel.text = @"Use iTunes App file sharing to export files.(Select all,Drag the file to Desktop)";
#endif
    
    
}

- (NSString *)getEmojiUnicodeString:(NSString*)emoji{
    
    unichar uniBuff[16] = {0};
    [emoji getCharacters:uniBuff range:NSMakeRange(0, emoji.length)];
    
    NSMutableString *unicodeString = [NSMutableString string];
    int i = 0;
    while (uniBuff[i]) {
        [unicodeString appendFormat:@"U+%04X ",uniBuff[i]];
        i++;
    }
    if([unicodeString hasSuffix:@" "]){
        [unicodeString deleteCharactersInRange:NSMakeRange(unicodeString.length-1, 1)];
    }
    
    return unicodeString;
}

//🏿 Unicode: U+1F3FF (U+D83C U+DFFF)，UTF-8: F0 9F 8F BF，GB: 9439C933
//🏿 编译后的存储格式(exe binary): 3CD8 FFDF
- (NSArray *)skinedEmojisForBaseEmoji:(NSString *)baseEmoji{
    
    NSString *skin[]= {@"🏻",@"🏼",@"🏽",@"🏾",@"🏿"};
    NSArray *skins = [NSArray arrayWithObjects:skin count:5];//Just like iOS sys build
    
    NSMutableArray *emojis = [NSMutableArray array];
    for (NSString *skinCode in skins) {
        NSString *skinedEmoji = [NSString stringWithFormat:@"%@%@",baseEmoji,skinCode];
        [emojis addObject:skinedEmoji];
    }
    return emojis;
}

- (void)getEmojiListFromSysKeyboard{
    
    NSUInteger emojiCount = 0;
    NSMutableDictionary *dictEmojiInCate = [NSMutableDictionary dictionary];
    NSMutableDictionary *dictEmojiSkined = [NSMutableDictionary dictionary];
    NSMutableDictionary *dictEmojiUnicode = [NSMutableDictionary dictionary];
    NSMutableArray *cateNames = [NSMutableArray array];
    
    
    Class UIKeyboardEmojiCategory_Class = NSClassFromString(@"UIKeyboardEmojiCategory");
    
    //read catetory
    //Anther method to read all category using "NSArray *list = [NSClassFromString(@"UIKeyboardEmojiCategory") categories];", should call "categoryForType:" first.
    int numberOfCategories = [UIKeyboardEmojiCategory_Class numberOfCategories];
    for (int index = 0 ; index < numberOfCategories;index ++) {
        
        id UIKeyboardEmojiCategory_inst = [UIKeyboardEmojiCategory_Class categoryForType:index];
        
        //name
        NSString *name = [UIKeyboardEmojiCategory_inst performSelector:@selector(name)];
        if (!name || [name isEqualToString:@"UIKeyboardEmojiCategoryRecent"]){
            continue;
        }
        
        [cateNames addObject:name];
        
        //UIKeyboardEmoji
        NSMutableArray *emojisInCate = [NSMutableArray array];
        NSArray *emojis = [UIKeyboardEmojiCategory_inst performSelector:@selector(emoji)];
        
        NSLog(@"cate:%@ count:%lu",name, (unsigned long)[emojis count]);
        
        //iOS9 Emoji Flags didn't loaded for a all new simulator or device.
        if ([name isEqualToString:@"UIKeyboardEmojiCategoryFlags"] && (0 == [emojis count])) {
            NSAssert(0, @"Show keyboard of emoji in system app, and tap 'flag' icon. Run this dump again.");
        }
        
        for (id UIKeyboardEmoji_inst in emojis) {
            
            NSString *key = [UIKeyboardEmoji_inst performSelector:@selector(key)];
            if (key) {
                emojiCount ++;
                
                //unicode
                NSString *unicodeString = [self getEmojiUnicodeString:key];
                if (unicodeString) {
                    [dictEmojiUnicode setObject:unicodeString forKey:key];
                }
                
                
                //Variant
                unsigned int  hasVariants = [UIKeyboardEmojiCategory_Class hasVariantsForEmoji:key];
                
                NSLog(@"%lu:%u:%@:%@",(unsigned long)emojiCount,hasVariants, key, unicodeString);
                
                [emojisInCate addObject:key];
                
                if (hasVariants == 0) {
                    //NSLog(@"没有变体");
                }
                else if (hasVariants == 1) {//☺⭐☀⛄...
                    //NSLog(@"有变体，有普通字体和emoji");
                }
                else if (hasVariants == 2) {//👍👦👧🏊🚵...
                    //NSLog(@"有变体，emoji的肤色");
                    
                    NSArray *skinToneEmojis = [self skinedEmojisForBaseEmoji:key];
                    [dictEmojiSkined setObject:skinToneEmojis forKey:key];
                    
                    //uncode
                    for (NSString *skinedKey in skinToneEmojis) {
                        NSString *unicodeString = [self getEmojiUnicodeString:skinedKey];
                        if (unicodeString) {
                            [dictEmojiUnicode setObject:unicodeString forKey:skinedKey];
                        }
                        
                        NSLog(@"  %@:%@",skinedKey, unicodeString);
                    }
                }
                else if (hasVariants == 3) {//✌☝
                    //NSLog(@"有变体，普通字体的肤色");
                    NSArray *skinToneEmojis = [self skinedEmojisForBaseEmoji:key];
                    [dictEmojiSkined setObject:skinToneEmojis forKey:key];
                    
                    //uncode
                    for (NSString *skinedKey in skinToneEmojis) {
                        NSString *unicodeString = [self getEmojiUnicodeString:skinedKey];
                        if (unicodeString) {
                            [dictEmojiUnicode setObject:unicodeString forKey:skinedKey];
                        }
                        NSLog(@"  %@:%@", skinedKey, unicodeString);
                    }
                }
                else {
                    NSLog(@"Other variants!");
                }
            }
        }
        
        [dictEmojiInCate setObject:emojisInCate forKey:name];
    }
    
#if TARGET_IPHONE_SIMULATOR
    NSString *hostHome = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_HOST_HOME"];
    NSString *basePath = [NSString stringWithFormat:@"%@/Emoji_iOS%@_Simulator",hostHome,[UIDevice currentDevice].systemVersion];
#else
    NSString *basePath = [NSString stringWithFormat:@"%@/Documents/Emoji_iOS%@_iPhone",NSHomeDirectory(),[UIDevice currentDevice].systemVersion];
#endif
    
    NSString *pathEmojiInCate =     [NSString stringWithFormat:@"%@_%luEmojis.plist",    basePath,(unsigned long)emojiCount];
    NSString *pathSkinTone =        [NSString stringWithFormat:@"%@_%luSkined.plist",    basePath,(unsigned long)dictEmojiSkined.allKeys.count];
    NSString *pathEmojiUnicode =    [NSString stringWithFormat:@"%@_%luUnicode.plist",   basePath,(unsigned long)dictEmojiUnicode.allKeys.count];
    NSString *pathEmojiCategories = [NSString stringWithFormat:@"%@_%luCategories.plist",basePath,(unsigned long)cateNames.count];
    
    
    //On iOS9.1 Emoji Flags are sorted by diffrent language.
    //id computeEmojiFlagsSortedByLanguage = [NSClassFromString(@"UIKeyboardEmojiCategory") performSelector:@selector(computeEmojiFlagsSortedByLanguage)];
    // NSLog(@"%@",computeEmojiFlagsSortedByLanguage);
    //id loadPrecomputedEmojiFlagCategory = [NSClassFromString(@"UIKeyboardEmojiCategory") performSelector:@selector(loadPrecomputedEmojiFlagCategory)];
    //NSLog(@"%@",loadPrecomputedEmojiFlagCategory);
    
    [dictEmojiInCate writeToFile:pathEmojiInCate atomically:YES];//Emoji may dumped in diff category
    [dictEmojiSkined writeToFile:pathSkinTone atomically:YES];
    [dictEmojiUnicode writeToFile:pathEmojiUnicode atomically:YES];
    [cateNames writeToFile:pathEmojiCategories atomically:YES];//Some category not display in keyboard
}


@end
