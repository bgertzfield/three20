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

/**
 * A high resolution timer.
 * Example:
 * [[TTTimer sharedInstance] startWithName:@"t1"]
 * ...
 * float elapsedSeconds = [[TTTimer sharedInstance] elapsedTimeWithName:@"t1"]
 */
@interface TTTimer : NSObject {
  NSMutableDictionary* _timers;
}

/**
 * Begin a timer with the given name.
 */
- (void) startWithName:(NSString*)name;

/**
 * Get the elapsed number of seconds for the given timer.
 */
- (float) elapsedTimeWithName:(NSString*)name;

/**
 * Get the elapsed number of seconds for the given timer and reset the timer.
 */
- (float) stopwatchTimeWithName:(NSString*)name;

@end


@interface TTTimer (TTSingleton)

// Access the singleton instance: [[TTTimer sharedInstance] <methods>]
+ (TTTimer*)sharedInstance;

@end
