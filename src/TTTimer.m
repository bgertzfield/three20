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

#import "Three20/TTTimer.h"

#include <assert.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

#import "Three20/TTCorePreprocessorMacros.h"

static mach_timebase_info_data_t timebase;


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTimer


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id) init {
  if (self = [super init]) {
    mach_timebase_info(&timebase);
    _timers = [[NSMutableDictionary alloc] init];
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
  TT_RELEASE_SAFELY(_timers);
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (float) machToSeconds:(uint64_t)elapsed {
  return
    ((float)elapsed)
    * ((float)timebase.numer)
    / ((float)timebase.denom)
    / 1000000000.0f;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) startWithName:(NSString*)name {
  uint64_t startTime = mach_absolute_time();
  [_timers setObject:[NSNumber numberWithUnsignedLongLong:startTime] forKey:name];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (float) elapsedTimeWithName:(NSString*)name {
  uint64_t startTime = [[_timers objectForKey:name] unsignedLongLongValue];
  uint64_t elapsed = mach_absolute_time() - startTime;

  return [self machToSeconds:elapsed];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (float) stopwatchTimeWithName:(NSString*)name {
  uint64_t startTime = [[_timers objectForKey:name] unsignedLongLongValue];
  uint64_t endTime = mach_absolute_time();
  uint64_t elapsed = endTime - startTime;
  
  [_timers setObject:[NSNumber numberWithUnsignedLongLong:endTime] forKey:name];
  
  return [self machToSeconds:elapsed];
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTimer (Singleton)

static TTTimer* sharedInstance = nil;

// This singleton is designed for ease of use in production code rather than
// test code. We could make this easier to test by solely implementing
// + (id)sharedInstance.
// As it stands, this implementation gracefully handles mistakes such as
// [TTTimer alloc] and trying to release the singleton.


///////////////////////////////////////////////////////////////////////////////////////////////////
+(id)sharedInstance {
  @synchronized(self) {
    if( nil == sharedInstance ) {
      sharedInstance = [[self alloc] init];
    }
  }
  return sharedInstance;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// Ensure that [TTTimer alloc] returns the singleton object.
+(id)allocWithZone:(NSZone*)zone {
  if( nil == sharedInstance ) {
    sharedInstance = [super allocWithZone:zone];
  }
  
  return sharedInstance;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(id)copyWithZone:(NSZone *)zone {
  return sharedInstance;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(id)retain {
  return sharedInstance;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(unsigned)retainCount {
  return NSUIntegerMax;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(oneway void)release {
  // Do nothing.
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(id)autorelease {
  return sharedInstance;    
}


@end
