//
//  HotKey.h
//  HotKey
//
//  Created by Rob Griffiths on 22/01/2013.
//  Copyright (c) 2013 Rob Griffiths. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface HotKey : NSObject
{
    UInt32 carbonKeyCode;
    UInt32 carbonModifierFlags;
    UInt32 hotKeyID;
    EventHotKeyRef carbonHotKeyRef;
}

@property (nonatomic) UInt32 keyCode;
@property (nonatomic) UInt32 modifierFlags;
@property (nonatomic, strong) void(^eventHandler)();

+(NSMutableDictionary *) registeredHotKeys;

+(HotKey *) registerHotKeyWithKeyCode:(UInt32)keyCode modifierFlags:(UInt32)modifierFlags error:(NSError **)error usingBlock:(void(^)())handlerBlock;

-(id) initWithKeyCode:(UInt32)keyCode modifierFlags:(UInt32)modifierFlags;
-(UInt32) cocoaModifierFlagsToCarbon: (UInt32)cocoaModifierFlags;
-(void) registerUsingBlock:(void (^)())handlerBlock error:(NSError **)error;
-(void) unregister;

@end
