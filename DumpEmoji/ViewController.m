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

#import "EmojiFoundation/EMFEmojiToken.h"

@interface ViewController ()
@property (nonatomic,strong)IBOutlet UILabel *textLabel;
@property (nonatomic,strong)UITextField *textField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    for (UIView *subView in self.view.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            _textField = (UITextField *)subView;
            break;
        }
    }
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(CGRectGetMaxX(_textField.frame) + 5, CGRectGetMinY(_textField.frame) - 8, 70, 44);
    button.backgroundColor = [UIColor lightGrayColor];
    [button setTitle:@"Unicode" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(actionUnicode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)actionUnicode {
    NSString *text = _textField.text;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                              NSLog(@"%@:%@", substring, [self getEmojiUnicodeStringUCS4:substring]);
                          }];
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
    self.textLabel.text = @"😀Dump finish!\n Use iTunes App file sharing to export files. (Select all,Drag the file to Desktop)";
#endif
    
    
}

- (BOOL)isValidComposedEmoji:(NSString *)emoji {
    __block NSUInteger count = 0;
    [emoji enumerateSubstringsInRange:NSMakeRange(0, emoji.length)
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                               count ++;
                               //NSLog(@"%@%@%@:%@", substring ,NSStringFromRange(substringRange), NSStringFromRange(enclosingRange), [self getEmojiUnicodeStringUCS4:substring]);
                           }];
    return (1 == count) ? YES : NO;
}

- (NSString *)getEmojiUnicodeString:(NSString*)emoji{
    
    unichar uniBuff[64] = {0};
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

- (NSString *)getEmojiUnicodeStringUCS4:(NSString*)emoji{
    
    uint32_t uniBuff[64] = {0};
    [emoji getCString:(char *)uniBuff maxLength:sizeof(uint32_t)*16 encoding:NSUTF32StringEncoding];
    
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

//🕵️ 侦探（男） Unicode: U+1F575 U+FE0F，UTF-8: F0 9F 95 B5 EF B8 8F
//🕵🏿 侦探（男） Unicode: U+1F575 U+1F3FF，UTF-8: F0 9F 95 B5 F0 9F 8F BF
- (NSArray *)skinedEmojisForBaseEmoji:(NSString *)baseEmoji{
    
    NSString *skin[]= {@"🏻",@"🏼",@"🏽",@"🏾",@"🏿"};//U+1F3FB, U+1F3FC, U+1F3FD, U+1F3FE, U+1F3FF
    NSArray *skins = [NSArray arrayWithObjects:skin count:5];//Just like iOS sys build
    
    NSRange range = [baseEmoji rangeOfString:@"\uFE0F" options:NSLiteralSearch];//🕵️🏌️
    if (range.location != NSNotFound) {
        baseEmoji = [baseEmoji substringToIndex:range.location];
    }
    
    NSMutableArray *emojis = [NSMutableArray array];
    for (NSString *skinCode in skins) {
        NSString *skinedEmoji = [NSString stringWithFormat:@"%@%@",baseEmoji,skinCode];
        
        NSAssert([self isValidComposedEmoji:skinedEmoji], @"%@->%@ composed emoji error!", baseEmoji, skinedEmoji);
        
        [emojis addObject:skinedEmoji];
    }
    return emojis;
}

//Variant 6 (iOS10.0 PeopleEmoji and ActivityEmoji)
//👱‍♀️ 金发女子 Unicode: U+1F471 U+200D U+2640 U+FE0F，UTF-8: F0 9F 91 B1 E2 80 8D E2 99 80 EF B8 8F
//👱🏿‍♀️ 金发女子 Unicode: U+1F471 U+1F3FF U+200D U+2640 U+FE0F，UTF-8: F0 9F 91 B1 F0 9F 8F BF E2 80 8D E2 99 80 EF B8 8F

//Variant 10 (iOS10.2 ProfessionEmoji)
//👨‍🍳 厨师（男） Unicode: U+1F468 U+200D U+1F373，UTF-8: F0 9F 91 A8 E2 80 8D F0 9F 8D B3
//👨🏿‍🍳 厨师（男） Unicode: U+1F468 U+1F3FF U+200D U+1F373，UTF-8: F0 9F 91 A8 F0 9F 8F BF E2 80 8D F0 9F 8D B3
- (NSArray *)skinedEmojisForBaseEmoji_6:(NSString *)baseEmoji{
    NSString *skin[]= {@"🏻",@"🏼",@"🏽",@"🏾",@"🏿"};//U+1F3FB, U+1F3FC, U+1F3FD, U+1F3FE, U+1F3FF
    NSArray *skins = [NSArray arrayWithObjects:skin count:5];
    
    NSMutableArray *emojis = [NSMutableArray array];
    for (NSString *skinCode in skins) {
        
        NSRange range = [baseEmoji rangeOfString:@"\u200D" options:NSLiteralSearch];
        if (range.location != NSNotFound) {
            NSMutableString *skinedEmoji = [NSMutableString stringWithString:baseEmoji];
            [skinedEmoji insertString:skinCode atIndex:range.location];
            
            //⛹️‍♀️🏋️‍♀️🏌️‍♀️🕵️‍♀️
            //⛹️‍♀️U+26F9 U+FE0F U+200D U+2640 U+FE0F
            //⛹🏿‍♀️U+26F9 U+1F3FF U+200D U+2640 U+FE0F (✅)
            //⛹️🏿‍♀️U+26F9 U+FE0F U+1F3FF U+200D U+2640 U+FE0F (❎)
            NSString *part1 = [baseEmoji substringToIndex:range.location];
            if ([part1 hasSuffix:@"\uFE0F"]) {
                [skinedEmoji deleteCharactersInRange:NSMakeRange(range.location - 1, 1)];
            }
            
            NSAssert([self isValidComposedEmoji:skinedEmoji], @"%@->%@ composed emoji error!", baseEmoji, skinedEmoji);
            
            [emojis addObject:skinedEmoji];
        }
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
    NSMutableArray *arraySkinedToNoSkin = [NSMutableArray array];
    
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
        
        //iOS10.2 and later, +[UIKeyboardEmojiCategory categoryForType:] called +[EMFEmojiCategory _emojiSetForIdentifier:]
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
            
            //unicode
            NSString *unicodeString = [self getEmojiUnicodeString:key];
            NSString *unicodeStringUCS4 = [self getEmojiUnicodeStringUCS4:key];
            if (![unicodeString isEqualToString:unicodeStringUCS4]) {
                unicodeString = [NSString stringWithFormat:@"%@ (%@)", unicodeStringUCS4, unicodeString];
            }
            [dictEmojiUnicode setObject:unicodeString forKey:key];
            
            //Skin Variant
            NSArray *skinToneEmojis = nil;
            
            //iOS7~iOS8.2 //+ (BOOL)hasVariantsForEmoji:(id)arg1;
            //iOS8.3+     //+ (unsigned int)hasVariantsForEmoji:(id)arg1; or + (unsigned long long)hasVariantsForEmoji:(id)arg1;
            unsigned long long hasVariants = (unsigned long long)[UIKeyboardEmojiCategory_Class hasVariantsForEmoji:key];
            NSLog(@"%lu:%llu:%@:'%@'",(unsigned long)emojiCountInCate, hasVariants, key, unicodeString);
            
            //iOS10.0 and later added PrivateFrameworks/EmojiFoundation.framework
            //iOS10.2 and later added @property(readonly, copy, nonatomic) NSArray *_skinToneVariantStrings;
            //🤝 should not have variants, but hasVariants == 6
            //🤹‍♀️🤹‍♂️ should have variants, but hasVariants == 0
            //check using class EMFEmojiToken
            Class emojiTokenClass = NSClassFromString(@"EMFEmojiToken");
            if (emojiTokenClass && [emojiTokenClass instancesRespondToSelector:@selector(_skinToneVariantStrings)]) {
                EMFEmojiToken *emojiToken = [emojiTokenClass emojiTokenWithString:key localeData:nil];
                if (emojiToken && emojiToken.supportsSkinToneVariants) {
                    skinToneEmojis = [emojiToken._skinToneVariantStrings subarrayWithRange:NSMakeRange(1, 5)];
                }
                
                if (hasVariants == 4) {//Changed to No Skin Tone. 👯‍♀️👯‍♂️🏌️‍♀️
                    NSLog(@"Changed to No Skin Tone:[%@]", key);
                    [arraySkinedToNoSkin addObject:key];
                }
                
            } else {
                if (hasVariants == 0) {
                    //NSLog(@"没有变体");
                }
                else if (hasVariants == 1) {//☺⭐☀⛄...
                    //NSLog(@"有变体，有普通字体和emoji");//Diff from AppleColorEmoji font from other font
                }
                else if (hasVariants == 2) {//👍👦👧🏊🚵...
                    //NSLog(@"有变体，emoji的肤色");
                    skinToneEmojis = [self skinedEmojisForBaseEmoji:key];
                }
                else if (hasVariants == 3) {//✌☝
                    //NSLog(@"有变体，普通字体的肤色");
                    skinToneEmojis = [self skinedEmojisForBaseEmoji:key];
                }
                else if (hasVariants == 4) {//Changed to No Skin Tone. 👯‍♀️👯‍♂️🏌️‍♀️
                    NSLog(@"Changed to No Skin Tone:[%@]", key);
                    [arraySkinedToNoSkin addObject:key];
                }
                else if (hasVariants == 6) {//Variant 6 (iOS10.0 PeopleEmoji and ActivityEmoji) 👱‍♀️👳‍♀️👮‍♀️... and 🚶‍♀️🏃‍♀️🏋️‍♀️...
                    skinToneEmojis = [self skinedEmojisForBaseEmoji_6:key];
                }
                else if (hasVariants == 10) {//Variant 10 (iOS10.2 ProfessionEmoji) 👩‍⚕️👨‍⚕️👩‍🌾👨‍🍳...
                    skinToneEmojis = [self skinedEmojisForBaseEmoji_6:key];
                }
                else {
                    NSLog(@"Other variants:[%@:%llu]", key, hasVariants);
                    NSAssert(0, @"Other variants:[%@:%llu]", key, hasVariants);
                }
            }
            
            //skined
            if (skinToneEmojis.count) {
                
                [dictEmojiSkined setObject:skinToneEmojis forKey:key];
                
                for (NSString *skinedKey in skinToneEmojis) {
                    
                    [arrayAllEmojis addObject:skinedKey];
                    
                    //uncode
                    NSString *unicodeString = [self getEmojiUnicodeString:skinedKey];
                    NSString *unicodeStringUCS4 = [self getEmojiUnicodeStringUCS4:skinedKey];
                    if (![unicodeString isEqualToString:unicodeStringUCS4]) {
                        unicodeString = [NSString stringWithFormat:@"%@ (%@)", unicodeStringUCS4, unicodeString];
                    }
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
    NSString *pathSkinedToNoSkin =  [NSString stringWithFormat:@"%@_%luSkinedToNoSkin.plist",basePath,(unsigned long)arraySkinedToNoSkin.count];
    
    NSString *pathEmojiAllString =  [NSString stringWithFormat:@"%@_%luEmojis.txt",         basePath,(unsigned long)arrayAllEmojis.count];
    
    
    [dictEmojiInCate writeToFile:pathEmojiInCate atomically:YES];//Emoji may dumped in diff category
    [dictEmojiSkined writeToFile:pathEmojiSkined atomically:YES];
    [dictEmojiUnicode writeToFile:pathEmojiUnicode atomically:YES];
    
    [arrayCateNames writeToFile:pathEmojiCategories atomically:YES];//Some category not display in keyboard
    [arrayAllEmojis writeToFile:pathEmojiAllArray atomically:YES];
    [arraySkinedToNoSkin writeToFile:pathSkinedToNoSkin atomically:YES];
    
    NSString *stringAllEmojis = [arrayAllEmojis componentsJoinedByString:@","];
    [stringAllEmojis writeToFile:pathEmojiAllString atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
}


@end
