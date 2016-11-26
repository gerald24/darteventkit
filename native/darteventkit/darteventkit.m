//
//  darteventkit.m
//  darteventkit Dart 2 Cocoa Bridge
//
//  Created by gerald on 24.11.16.
//  Copyright © 2016 Gerald Leeb. All rights reserved.
//

#import "darteventkit.h"


// see https://www.dartlang.org/articles/dart-vm/native-extensions

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope);

DART_EXPORT Dart_Handle darteventkit_Init(Dart_Handle parent_library) {
    if (Dart_IsError(parent_library)) {
        return parent_library;
    }
    
    Dart_Handle result_code =
    Dart_SetNativeResolver(parent_library, ResolveName, NULL);
    if (Dart_IsError(result_code)) {
        return result_code;
    }
    
    return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
    if (Dart_IsError(handle)) {
        Dart_PropagateError(handle);
    }
    return handle;
}

// Obj-C Runtime Bridge using autoreleasepool

void calendarEvents(Dart_NativeArguments arguments) {
    Dart_EnterScope();
    
    Dart_Handle dartCalendarNameHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
    if (Dart_IsString(dartCalendarNameHandle)) {
        const char* calendarCName;
        HandleError(Dart_StringToCString(dartCalendarNameHandle, &calendarCName));

        @autoreleasepool {
            NSString* calendarName = [NSString stringWithCString:calendarCName encoding:NSUTF8StringEncoding];
            const char* version = [[EventJsonSerialization eventsAsJsonForCalendarNamed: calendarName] UTF8String];
            Dart_Handle result = HandleError(Dart_NewStringFromCString(version));
            Dart_SetReturnValue(arguments, result);
        }
    }
    Dart_ExitScope();
}


struct FunctionLookup {
    const char* name;
    Dart_NativeFunction function;
};

typedef struct FunctionLookup FunctionLookup;

FunctionLookup function_list[] = {
    {"calendarEvents", calendarEvents},
    {NULL, NULL}};


FunctionLookup no_scope_function_list[] = {
//    {"calendarEvents", calendarEvents},
    {NULL, NULL}
};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
    if (!Dart_IsString(name)) {
        return NULL;
    }
    Dart_NativeFunction result = NULL;
    if (auto_setup_scope == NULL) {
        return NULL;
    }
    
    Dart_EnterScope();
    const char* cname;
    HandleError(Dart_StringToCString(name, &cname));
    
    for (int i=0; function_list[i].name != NULL; ++i) {
        if (strcmp(function_list[i].name, cname) == 0) {
            *auto_setup_scope = true;
            result = function_list[i].function;
            break;
        }
    }
    
    if (result != NULL) {
        Dart_ExitScope();
        return result;
    }
    
    for (int i=0; no_scope_function_list[i].name != NULL; ++i) {
        if (strcmp(no_scope_function_list[i].name, cname) == 0) {
            *auto_setup_scope = false;
            result = no_scope_function_list[i].function;
            break;
        }
    }
    
    Dart_ExitScope();
    return result;
}
