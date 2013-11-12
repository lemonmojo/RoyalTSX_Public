//
//  ConnectionStatusArguments.h
//  mRemoteMac
//
//  Created by Felix Deimel on 22.03.12.
//  Copyright (c) 2012 Lemon Mojo. All rights reserved.
//

#import "mrShared.h"

@interface ConnectionStatusArguments : NSObject {
    mrConnectionStatus status;
    int errorNumber;
    NSString *errorMessage;
}

@property (nonatomic, readwrite) mrConnectionStatus status;
@property (nonatomic, readwrite) int errorNumber;
@property (nonatomic, retain) NSString *errorMessage;

-(id)initWithStatus:(mrConnectionStatus)aStatus;
-(id)initWithStatus:(mrConnectionStatus)aStatus andErrorNumber:(int)aErrorNumber;
-(id)initWithStatus:(mrConnectionStatus)aStatus andErrorNumber:(int)aErrorNumber andErrorMessage:(NSString*)aErrorMessage;

@end
