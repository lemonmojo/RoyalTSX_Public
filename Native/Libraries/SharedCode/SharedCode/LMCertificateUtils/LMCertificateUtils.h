//
//  LMCertificateUtils.h
//  CertificateVerificationTest
//
//  Created by Felix Deimel on 01.07.13.
//  Copyright (c) 2013 Felix Deimel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Security/Security.h>
#import <CoreServices/CoreServices.h>
#import <CommonCrypto/CommonDigest.h>

@interface LMCertificateUtils : NSObject

+(BOOL)verifyCertificateWithCN:(NSString*)cn;
+(BOOL)verifyCertificateWithCN:(NSString*)cn andFingerprint:(NSString*)fingerprint;

@end
