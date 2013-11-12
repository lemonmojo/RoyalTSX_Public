//
//  ConnectionStatusArguments.m
//  mRemoteMac
//
//  Created by Felix Deimel on 22.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import "ConnectionStatusArguments.h"

@implementation ConnectionStatusArguments

@synthesize status, errorNumber, errorMessage;

-(id)initWithStatus:(mrConnectionStatus)aStatus {
    if (![super init])
		return nil;
    
    self.status = aStatus;
    
    return self;
}

-(id)initWithStatus:(mrConnectionStatus)aStatus andErrorNumber:(int)aErrorNumber {
    if (![super init])
		return nil;
    
    self.status = aStatus;
    self.errorNumber = aErrorNumber;
    
    return self;
}

-(id)initWithStatus:(mrConnectionStatus)aStatus andErrorNumber:(int)aErrorNumber andErrorMessage:(NSString*)aErrorMessage {
    if (![super init])
		return nil;
    
    self.status = aStatus;
    self.errorNumber = aErrorNumber;
    self.errorMessage = aErrorMessage;
    
    return self;
}

@end
