//
//  HotKey.m
//  HotKey
//
//  Created by Rob Griffiths on 22/01/2013.
//  Copyright (c) 2013 Rob Griffiths. All rights reserved.
//

#import "HotKey.h"

@implementation HotKey

@synthesize keyCode = _keyCode;
@synthesize modifierFlags = _modifierFlags;
@synthesize eventHandler;

+(void)initialize
{
    EventTypeSpec keyDownTypeSpec;
    keyDownTypeSpec.eventClass = kEventClassKeyboard;
    keyDownTypeSpec.eventKind = kEventHotKeyPressed;
    
	OSStatus err = InstallEventHandler(GetEventDispatcherTarget(), HotKeyHandler, 1, &keyDownTypeSpec, NULL, NULL);
    
    if (err != noErr) {
        NSLog(@"%d", err);
    }
}

+(NSMutableDictionary *) registeredHotKeys
{
    static NSMutableDictionary *_registeredHotKeys = nil;
    if (_registeredHotKeys == nil) {
        _registeredHotKeys = [[NSMutableDictionary alloc] init];
    }
    
    return _registeredHotKeys;
}

+(OSType) uniqueID
{
    static OSType _uniqueID = 0;
    _uniqueID++;
    
    return _uniqueID;
}

+(HotKey *) registerHotKeyWithKeyCode:(UInt32)keyCode modifierFlags:(UInt32)modifierFlags error:(NSError *__autoreleasing *)error usingBlock:(void(^)())handlerBlock
{
    HotKey *hotKey = [[HotKey alloc] initWithKeyCode:keyCode modifierFlags:modifierFlags];
    
    [hotKey registerUsingBlock:handlerBlock error:error];
    
    return hotKey;
}

-(id) initWithKeyCode:(UInt32)keyCode modifierFlags:(UInt32)modifierFlags
{
    if ((self = [self init])) {
        self.keyCode = keyCode;
        self.modifierFlags = modifierFlags;
    }
    
    return self;
}

-(void) registerUsingBlock:(void (^)())handlerBlock error:(NSError *__autoreleasing *)error
{
    OSStatus err;
    
    EventHotKeyID carbonHotKeyID;
    carbonHotKeyID.id = [HotKey uniqueID];
    carbonHotKeyID.signature = 'HotK';
    
    hotKeyID = carbonHotKeyID.id;
    
    if (handlerBlock) {
        self.eventHandler = handlerBlock;
    }
    
    if ([[[HotKey registeredHotKeys] allValues] containsObject:self]) {
        [self unregister];
    }
    
	err = RegisterEventHotKey(self.keyCode, carbonModifierFlags, carbonHotKeyID, GetEventDispatcherTarget(), kEventHotKeyExclusive, &carbonHotKeyRef);
    
	if (err != noErr) {
        NSLog(@"Could not register global hotkey");
        *error = [NSError errorWithDomain:@"HotKey::registerUsingBlock" code:1 userInfo:@{
                NSLocalizedDescriptionKey: @"Could not register global hotkey"
                  }];
	}
    
    [[HotKey registeredHotKeys] setValue:self forKey:[NSString stringWithFormat:@"%d", hotKeyID]];
}

-(void) unregister
{
    OSStatus err = UnregisterEventHotKey(carbonHotKeyRef);
    
    if (err != noErr) {
        NSLog(@"%d", err);
    }
    
    [[HotKey registeredHotKeys] removeObjectForKey:[NSString stringWithFormat:@"%d", hotKeyID]];
    hotKeyID = 0;
    carbonHotKeyRef = nil;
}

- (void)setModifierFlags:(UInt32)modifierFlags
{
    carbonModifierFlags = [self cocoaModifierFlagsToCarbon: modifierFlags];
}

- (UInt32) cocoaModifierFlagsToCarbon: (UInt32)cocoaModifierFlags
{
    UInt32 modifierFlags = 0;
    if (cocoaModifierFlags & NSCommandKeyMask) {
        modifierFlags |= cmdKey;
    }
    
    if (cocoaModifierFlags & NSAlternateKeyMask) {
        modifierFlags |= optionKey;
    }
    
    if (cocoaModifierFlags & NSControlKeyMask) {
        modifierFlags |= controlKey;
    }
    
    if (cocoaModifierFlags & NSShiftKeyMask) {
        modifierFlags |= shiftKey;
    }
    
    return modifierFlags;
}

#pragma mark - Carbon Callbacks

OSStatus HotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    OSStatus err;
    if (GetEventClass(theEvent) != kEventClassKeyboard) {
		return noErr;
    }
	
	EventHotKeyID carbonHotKeyID;
    err = GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(carbonHotKeyID), NULL, &carbonHotKeyID);
    
	if (err != noErr) {
		return err;
    }
	
	HotKey *hotKey = [[HotKey registeredHotKeys] valueForKey:[NSString stringWithFormat:@"%d", carbonHotKeyID.id]];
    
	if (hotKey == nil) {
		return noErr;
    }
	
	if (hotKey.eventHandler != nil) {
        hotKey.eventHandler();
    }
	
    return noErr;
}

@end
