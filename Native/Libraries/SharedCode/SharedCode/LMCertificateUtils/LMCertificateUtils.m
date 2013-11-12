//
//  LMCertificateUtils.m
//  CertificateVerificationTest
//
//  Created by Felix Deimel on 01.07.13.
//  Copyright (c) 2013 Felix Deimel. All rights reserved.
//

#import "LMCertificateUtils.h"

@implementation LMCertificateUtils

+(BOOL)verifyCertificateWithCN:(NSString*)cn
{
    return [LMCertificateUtils verifyCertificateWithCN:cn andFingerprint:nil];
}

+(BOOL)verifyCertificateWithCN:(NSString*)cn andFingerprint:(NSString*)fingerprint
{
    NSArray* certs = GetAllCertificates();
    SecCertificateRef certRef = NULL;
    
    for (int i = 0; i < [certs count]; i++) {
        SecCertificateRef ref = (SecCertificateRef)[certs objectAtIndex:i];
        CFStringRef commonName = NULL;
        SecCertificateCopyCommonName(ref, &commonName);
        
        if ([cn isEqualToString:(NSString*)commonName])
            certRef = ref;
        
        if (commonName)
            CFRelease(commonName);
        
        if (certRef)
            break;
    }

    const CSSM_OID *myPolicyOID = &CSSMOID_APPLE_X509_BASIC;
    SecPolicyRef policyRef = nil;
    
    SecTrustRef trustRef = nil;
    SecTrustResultType result = kSecTrustResultInvalid;
    
    OSStatus statusEvaluateCert = -1;
    
    if (certRef) {
        if ([fingerprint length] > 0) {
            CFDataRef certData = SecCertificateCopyData(certRef);
            
            if (certData) {
                NSString* certFingerprint = sha1((NSData*)certData);
                
                CFRelease(certData);
                
                if (![fingerprint isEqualToString:certFingerprint]) {
                    return NO;
                }
            }
        }
        
        OSStatus statusFindPolicy = FindPolicy (myPolicyOID, &policyRef);
        
        if (!statusFindPolicy) {
            statusEvaluateCert = EvaluateCert ((SecCertificateRef)certRef,
                                               (CFTypeRef) policyRef,
                                               &result, &trustRef);
        }
    }
    
    if (policyRef)
        CFRelease(policyRef);
    
    if (trustRef)
        CFRelease(trustRef);
    
    if (!statusEvaluateCert)
        return result == kSecTrustResultProceed;
    
    return NO;
}

NSArray* GetAllCertificates ()
{
    SecKeychainRef keychain = NULL;
    SecKeychainCopyDefault(&keychain);
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassCertificate, kSecClass,
                           [NSArray arrayWithObject:(id)keychain], kSecMatchSearchList,
                           kCFBooleanTrue, kSecReturnRef,
                           kSecMatchLimitAll, kSecMatchLimit,
                           nil];
    NSArray *items = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&items);
    
    if (status)
        return nil;
    
    return [items autorelease];
}

NSString* sha1 (NSData* certData)
{
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(certData.bytes, (CC_LONG)certData.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x:",sha1Buffer[i]];
    }
    
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
}

OSStatus GetCertRef (SecKeychainAttributeList *attrList, SecKeychainItemRef *itemRef)
{
    OSStatus status;
    SecKeychainSearchRef searchReference = nil;
    
    status = SecKeychainSearchCreateFromAttributes (NULL, kSecCertificateItemClass, attrList, &searchReference);
    
    status = SecKeychainSearchCopyNext (searchReference, itemRef);
    
    if (searchReference)
        CFRelease(searchReference);
    
    return (status);
}

OSStatus FindPolicy (const CSSM_OID *policyOID, SecPolicyRef *policyRef)
{
    OSStatus status1;
    OSStatus status2;
    SecPolicySearchRef searchRef;
    
    status1 = SecPolicySearchCreate (CSSM_CERT_X_509v3, policyOID, NULL, &searchRef);
    
    status2 = SecPolicySearchCopyNext (searchRef, policyRef);
    
    if (searchRef)
        CFRelease(searchRef);
    
    return (status2);
}

OSStatus EvaluateCert (SecCertificateRef cert, CFTypeRef policyRef, SecTrustResultType *result, SecTrustRef *pTrustRef)
{
    OSStatus status1;
    OSStatus status2;
    
    SecCertificateRef evalCertArray[1] = { cert };
    CFArrayRef cfCertRef = CFArrayCreate ((CFAllocatorRef) NULL,
                                          (void *)evalCertArray, 1,
                                          &kCFTypeArrayCallBacks);
    if (!cfCertRef)
        return memFullErr;
    
    status1 = SecTrustCreateWithCertificates(cfCertRef, policyRef, pTrustRef);
    
    if (status1)
        return status1;
    
    status2 = SecTrustEvaluate (*pTrustRef, result);
    
    if (cfCertRef)
        CFRelease(cfCertRef);
    
    return (status2);
}

@end
