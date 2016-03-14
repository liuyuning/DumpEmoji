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
    
    self.textLabel.text = nil;
    
    //iOS9 Emoji Flags didn't loaded for a all new simulator or device.
    //iOS9.1 Emoji Flags are sorted by diffrent language.
    if (![self isCategoryFlagsLoad]) {
        self.textLabel.text = @"⚠️Show keyboard of Emoji in system app, and tap 'flag' icon. Run this dump again.";
        return;
    }
    
    NSLog(@"Dump start!");
    
    [self getEmojiListFromSysKeyboard];
    
    NSLog(@"Dump finish!");
    
#if TARGET_IPHONE_SIMULATOR
    NSString *hostHome = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_HOST_HOME"];
    self.textLabel.text = [NSString stringWithFormat:@"😀Dump finish!\n Files under %@/",hostHome];
#else
    self.textLabel.text = @"😀Use iTunes App file sharing to export files.(Select all,Drag the file to Desktop)";
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



- (BOOL)isCategoryFlagsLoad{
    //On iOS9.1 Emoji Flags are sorted by diffrent language.
    
    //    id computeEmojiFlagsSortedByLanguage = [NSClassFromString(@"UIKeyboardEmojiCategory") performSelector:@selector(computeEmojiFlagsSortedByLanguage)];
    //    for (NSString *key in computeEmojiFlagsSortedByLanguage) {
    //        NSLog(@"%@",key);
    //    }
    //    //NSLog(@"%@",computeEmojiFlagsSortedByLanguage);
    //    id loadPrecomputedEmojiFlagCategory = [NSClassFromString(@"UIKeyboardEmojiCategory") performSelector:@selector(loadPrecomputedEmojiFlagCategory)];
    //    NSLog(@"%@",loadPrecomputedEmojiFlagCategory);
    
    Class UIKeyboardEmojiCategory_Class = NSClassFromString(@"UIKeyboardEmojiCategory");
    int numberOfCategories = [UIKeyboardEmojiCategory_Class numberOfCategories];
    
    for (int index = 0 ; index < numberOfCategories; index ++) {
        id UIKeyboardEmojiCategory_inst = [UIKeyboardEmojiCategory_Class categoryForType:index];
        
        NSString *name = [UIKeyboardEmojiCategory_inst name];
        NSArray *emojis = [UIKeyboardEmojiCategory_inst emoji];
        
        if ([name isEqualToString:@"UIKeyboardEmojiCategoryFlags"] && (0 == [emojis count])) {
            return NO;
        }
    }
    return YES;
}


- (void)getEmojiListFromSysKeyboard{
    
    NSUInteger emojiCountInCate = 0;
    
    NSMutableDictionary *dictEmojiInCate = [NSMutableDictionary dictionary];
    NSMutableDictionary *dictEmojiSkined = [NSMutableDictionary dictionary];
    NSMutableDictionary *dictEmojiUnicode = [NSMutableDictionary dictionary];
    
    NSMutableArray *arrayCateNames = [NSMutableArray array];
    NSMutableArray *arrayAllEmojis = [NSMutableArray array];
    
    NSMutableString *stringAllEmojis = [NSMutableString string];
    
    //read catetory
    //Anther method to read all category using "NSArray *list = [NSClassFromString(@"UIKeyboardEmojiCategory") categories];", should call "categoryForType:" first.
    Class UIKeyboardEmojiCategory_Class = NSClassFromString(@"UIKeyboardEmojiCategory");
    
    NSMutableArray *categoryIndexes = [NSMutableArray array];
    
    //iOS9.1 ([UIKeyboardEmojiCategory numberOfCategories] has more Emoji, but not same as displayed on Emoji Keyboard)
    if ([UIKeyboardEmojiCategory_Class respondsToSelector:@selector(enabledCategoryIndexes)]) {
        NSArray *enabledCategoryIndexes = [UIKeyboardEmojiCategory_Class enabledCategoryIndexes];
        [categoryIndexes setArray:enabledCategoryIndexes];
        //        for (NSNumber *index in enabledCategoryIndexes) {
        //            NSLog(@"%@:%d", index, [UIKeyboardEmojiCategory_Class categoryIndexForCategoryType:[index intValue]]);
        //        }
    }
    //iOS8
    else{
        int numberOfCategories = [UIKeyboardEmojiCategory_Class numberOfCategories];
        for (int index = 0 ; index < numberOfCategories; index ++){
            [categoryIndexes addObject:@(index)];
        }
    }
    
    for (NSNumber *index in categoryIndexes) {
        
        id UIKeyboardEmojiCategory_inst = [UIKeyboardEmojiCategory_Class categoryForType:index.intValue];
        
        //name
        NSString *name = [UIKeyboardEmojiCategory_inst performSelector:@selector(name)];
        if (!name || [name isEqualToString:@"UIKeyboardEmojiCategoryRecent"]){
            continue;
        }
        [arrayCateNames addObject:name];
        
        //UIKeyboardEmoji
        NSMutableArray *emojisInCate = [NSMutableArray array];
        NSArray *emojis = [UIKeyboardEmojiCategory_inst performSelector:@selector(emoji)];
        
        NSLog(@"cate:%@ count:%lu",name, (unsigned long)[emojis count]);
        
        for (id UIKeyboardEmoji_inst in emojis) {
            
            NSString *key = [UIKeyboardEmoji_inst performSelector:@selector(key)];
            if (key.length < 1) {
                continue;
            }
            
            emojiCountInCate ++;
            
            [emojisInCate addObject:key];
            [arrayAllEmojis addObject:key];
            [stringAllEmojis appendString:key];
            
            //unicode
            NSString *unicodeString = [self getEmojiUnicodeString:key];
            [dictEmojiUnicode setObject:unicodeString forKey:key];
            
            BOOL hasSkined = NO;
            
            //Variant
            unsigned int hasVariants = [UIKeyboardEmojiCategory_Class hasVariantsForEmoji:key];
            NSLog(@"%lu:%u:%@:'%@'",(unsigned long)emojiCountInCate,hasVariants, key, unicodeString);
            
            if (hasVariants == 0) {
                //NSLog(@"没有变体");
            }
            else if (hasVariants == 1) {//☺⭐☀⛄...
                //NSLog(@"有变体，有普通字体和emoji");//Diff from AppleColorEmoji font from other font
            }
            else if (hasVariants == 2) {//👍👦👧🏊🚵...
                //NSLog(@"有变体，emoji的肤色");
                hasSkined = YES;
            }
            else if (hasVariants == 3) {//✌☝
                //NSLog(@"有变体，普通字体的肤色");
                hasSkined = YES;
            }
            else {
                NSLog(@"Other variants!");
            }
            
            //skined
            if (hasSkined) {
                NSArray *skinToneEmojis = [self skinedEmojisForBaseEmoji:key];
                [dictEmojiSkined setObject:skinToneEmojis forKey:key];//✍
                
                for (NSString *skinedKey in skinToneEmojis) {
                    
                    [arrayAllEmojis addObject:skinedKey];
                    [stringAllEmojis appendString:skinedKey];
                    
                    //uncode
                    NSString *unicodeString = [self getEmojiUnicodeString:skinedKey];
                    [dictEmojiUnicode setObject:unicodeString forKey:skinedKey];
                    
                    NSLog(@"  %@:'%@'", skinedKey, unicodeString);
                }
            }
        }
        
        [dictEmojiInCate setObject:emojisInCate forKey:name];
    }
    
    //NSLog(@"%@",stringAllEmojis);
    
#if TARGET_IPHONE_SIMULATOR
    NSString *hostHome = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_HOST_HOME"];
    NSString *basePath = [NSString stringWithFormat:@"%@/Emoji_iOS%@_Simulator",hostHome,[UIDevice currentDevice].systemVersion];
#else
    NSString *basePath = [NSString stringWithFormat:@"%@/Documents/Emoji_iOS%@_iPhone",NSHomeDirectory(),[UIDevice currentDevice].systemVersion];
#endif
    
    NSString *pathEmojiInCate =     [NSString stringWithFormat:@"%@_%luEmojisInCate.plist", basePath,(unsigned long)emojiCountInCate];
    NSString *pathEmojiSkined =     [NSString stringWithFormat:@"%@_%luSkined.plist",       basePath,(unsigned long)dictEmojiSkined.allKeys.count];
    NSString *pathEmojiUnicode =    [NSString stringWithFormat:@"%@_%luUnicode.plist",      basePath,(unsigned long)dictEmojiUnicode.allKeys.count];
    
    NSString *pathEmojiCategories = [NSString stringWithFormat:@"%@_%luCategories.plist",   basePath,(unsigned long)arrayCateNames.count];
    NSString *pathEmojiAllArray =   [NSString stringWithFormat:@"%@_%luEmojis.plist",       basePath,(unsigned long)arrayAllEmojis.count];
    
    NSString *pathEmojiAllString =  [NSString stringWithFormat:@"%@_%luEmojis.txt",         basePath,(unsigned long)arrayAllEmojis.count];
    
    
    [dictEmojiInCate writeToFile:pathEmojiInCate atomically:YES];//Emoji may dumped in diff category
    [dictEmojiSkined writeToFile:pathEmojiSkined atomically:YES];
    [dictEmojiUnicode writeToFile:pathEmojiUnicode atomically:YES];
    
    [arrayCateNames writeToFile:pathEmojiCategories atomically:YES];//Some category not display in keyboard
    
    [arrayAllEmojis writeToFile:pathEmojiAllArray atomically:YES];
    [stringAllEmojis writeToFile:pathEmojiAllString atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
}


@end
