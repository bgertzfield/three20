//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20/TTNetworkReachability.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Three20/TTDebug.h"

#define kShouldPrintReachabilityFlags 1

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment) {
#if kShouldPrintReachabilityFlags
  
  NSLog(@"TTNetworkReachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
        (flags & kSCNetworkReachabilityFlagsIsWWAN)          ? 'W' : '-',
        (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
        
        (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
        (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
        (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
        (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
        comment
        );
#endif
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTNetworkReachability


//////////////////////////////////////////////////////////////////////////////////////////////////
static void ReachabilityCallback(SCNetworkReachabilityRef target,
                                 SCNetworkReachabilityFlags flags,
                                 void* info) {
#pragma unused (target, flags)
  TTDASSERT(info != NULL); // info was NULL in ReachabilityCallback
  
  // info was wrong class in ReachabilityCallback
  TTDASSERT([(NSObject*) info isKindOfClass: [TTNetworkReachability class]]);
  
  // We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
  // in case someone uses the TTNetworkReachablity object in a different thread.
  NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
  
  TTNetworkReachability* noteObject = (TTNetworkReachability*) info;
  // Post a notification to notify the client that the network reachability changed.
  [[NSNotificationCenter defaultCenter]
   postNotificationName: kReachabilityChangedNotification
   object: noteObject];
  
  [myPool release];
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) startNotifer {
  BOOL retVal = NO;
  SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
  if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
    if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef,
                                                 CFRunLoopGetCurrent(),
                                                 kCFRunLoopDefaultMode)) {
      retVal = YES;
    }
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (void) stopNotifer {
  if (nil != _reachabilityRef) {
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef,
                                               CFRunLoopGetCurrent(),
                                               kCFRunLoopDefaultMode);
  }
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
  [self stopNotifer];
  if (nil != _reachabilityRef) {
    CFRelease(_reachabilityRef);
  }
  [super dealloc];
}


//////////////////////////////////////////////////////////////////////////////////////////////////
+ (TTNetworkReachability*) reachabilityWithHostName: (NSString*) hostName {
  TTNetworkReachability* retVal = NULL;
  SCNetworkReachabilityRef reachability =
    SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
  if (reachability != NULL) {
    retVal= [[[self alloc] init] autorelease];
    if (retVal != NULL) {
      retVal->_reachabilityRef = reachability;
      retVal->_localWiFiRef = NO;
    }
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
+ (TTNetworkReachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress {
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
  TTNetworkReachability* retVal = NULL;
  if (nil != reachability) {
    retVal= [[[self alloc] init] autorelease];
    if (nil != retVal) {
      retVal->_reachabilityRef = reachability;
      retVal->_localWiFiRef = NO;
    }
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
+ (TTNetworkReachability*) reachabilityForInternetConnection {
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;
  return [self reachabilityWithAddress: &zeroAddress];
}


//////////////////////////////////////////////////////////////////////////////////////////////////
+ (TTNetworkReachability*) reachabilityForLocalWiFi {
  [super init];
  struct sockaddr_in localWifiAddress;
  bzero(&localWifiAddress, sizeof(localWifiAddress));
  localWifiAddress.sin_len = sizeof(localWifiAddress);
  localWifiAddress.sin_family = AF_INET;
  // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
  localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
  TTNetworkReachability* retVal = [self reachabilityWithAddress: &localWifiAddress];
  if(nil != retVal) {
    retVal->_localWiFiRef = YES;
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Network Flag Handling


//////////////////////////////////////////////////////////////////////////////////////////////////
- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags {
  PrintReachabilityFlags(flags, "localWiFiStatusForFlags");
  
  BOOL retVal = NotReachable;
  if((flags & kSCNetworkReachabilityFlagsReachable)
     && (flags & kSCNetworkReachabilityFlagsIsDirect)) {
    retVal = ReachableViaWiFi;  
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags {
  PrintReachabilityFlags(flags, "networkStatusForFlags");
  if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
    // if target host is not reachable
    return NotReachable;
  }
  
  BOOL retVal = NotReachable;
  
  if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
    // if target host is reachable and no connection is required
    //  then we'll assume (for now) that your on Wi-Fi
    retVal = ReachableViaWiFi;
  }
  
  
  if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
       (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
    // ... and the connection is on-demand (or on-traffic) if the
    //     calling application is using the CFSocketStream or higher APIs
    
    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
      // ... and no [user] intervention is needed
      retVal = ReachableViaWiFi;
    }
  }
  
  if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
    // ... but WWAN connections are OK if the calling application
    //     is using the CFNetwork (CFSocketStream?) APIs.
    retVal = ReachableViaWWAN;
  }
  return retVal;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) connectionRequired {
  TTDASSERT(nil != _reachabilityRef); // connectionRequired called with NULL reachabilityRef
  SCNetworkReachabilityFlags flags;
  if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
    return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
  }
  return NO;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
- (NetworkStatus) currentReachabilityStatus {
  TTDASSERT(nil != _reachabilityRef); // currentNetworkStatus called with NULL reachabilityRef
  NetworkStatus retVal = NotReachable;
  SCNetworkReachabilityFlags flags;
  if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
    if (_localWiFiRef) {
      retVal = [self localWiFiStatusForFlags: flags];

    } else {
      retVal = [self networkStatusForFlags: flags];
    }
  }
  return retVal;
}


@end
