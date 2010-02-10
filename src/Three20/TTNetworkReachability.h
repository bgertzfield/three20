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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef enum {
  NotReachable = 0,
  ReachableViaWiFi,
  ReachableViaWWAN
} NetworkStatus;

#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"

@interface TTNetworkReachability : NSObject {
  BOOL                      _localWiFiRef;
  SCNetworkReachabilityRef  _reachabilityRef;
}

/**
 * Check the TTNetworkReachability of a particular host name. 
 */
+ (TTNetworkReachability*) reachabilityWithHostName: (NSString*) hostName;

/**
 * Check the TTNetworkReachability of a particular IP address. 
 */
+ (TTNetworkReachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;

/**
 * Check whether the default route is available.  
 * Should be used by applications that do not connect to a particular host
 */
+ (TTNetworkReachability*) reachabilityForInternetConnection;

/**
 * Check whether a local wifi connection is available.
 */
+ (TTNetworkReachability*) reachabilityForLocalWiFi;

/**
 * Start listening for TTNetworkReachability notifications on the current run loop.
 * When reachability changes, a notification of the type kReachabilityChangedNotification is
 * posted.
 */
- (BOOL) startNotifer;
- (void) stopNotifer;

- (NetworkStatus) currentReachabilityStatus;

/**
 * WWAN may be available, but not active until a connection has been established.
 * WiFi may require a connection for VPN on Demand.
 */
- (BOOL) connectionRequired;

@end


