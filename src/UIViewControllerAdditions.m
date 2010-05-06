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

#import "Three20/UIViewControllerAdditions.h"

// UI
#import "Three20/TTGlobalUI.h"
#import "Three20/TTNavigator.h"
#import "Three20/TTViewController.h"

// UI (private)
#import "Three20/UIViewControllerAdditionsInternal.h"

// Network
#import "Three20/TTURLMap.h"

// Core
#import "Three20/TTCorePreprocessorMacros.h"
#import "Three20/TTGlobalCore.h"
#import "Three20/TTDebug.h"
#import "Three20/TTDebugFlags.h"

static NSMutableDictionary* gNavigatorURLs = nil;
static NSMutableDictionary* gSuperControllers = nil;
static NSMutableDictionary* gPopupViewControllers = nil;

// Garbage collection state
static NSMutableSet*        gsCommonControllers     = nil;
static NSTimer*             gsGarbageCollectorTimer = nil;

static const NSTimeInterval kGarbageCollectionInterval = 20;


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface TTPopupView : UIView {
  UIViewController* _popupViewController;
}

@property (nonatomic, retain) UIViewController* popupViewController;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTPopupView

@synthesize popupViewController = _popupViewController;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [_popupViewController release];

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didAddSubview:(UIView*)subview {
  TTDCONDITIONLOG(TTDFLAG_VIEWCONTROLLERS, @"ADD %@", subview);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willRemoveSubview:(UIView*)subview {
  TTDCONDITIONLOG(TTDFLAG_VIEWCONTROLLERS, @"REMOVE %@", subview);
  [self removeFromSuperview];
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UIViewController (TTCategory)


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNavigatorURL:(NSURL*)URL query:(NSDictionary*)query {
  if (self = [self init]) {
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Garbage Collection


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSMutableSet*)commonControllers {
  if (nil == gsCommonControllers) {
    gsCommonControllers = [[NSMutableSet alloc] init];
  }
  return gsCommonControllers;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Three20 used to provide an overridden dealloc method that all UIViewControllers
 * implementations would use to remove their originalNavigatorURLs and other properties.
 * Apple has stated that using TTSwapMethod to swap dealloc with a custom implementation isn't
 * ok, so now we do garbage collection.
 *
 * The basic idea.
 * Whenever you set the original navigator URL path for a controller, we add the controller
 * to a global navigator controllers list. We then run the following garbage collection every
 * kGarbageCollectionInterval seconds. If any controllers have a retain count of 1, then
 * we can safely say that nobody is using it anymore and release it.
 */
+ (void)doGarbageCollection {
  NSMutableSet* controllers = [UIViewController commonControllers];

  if ([controllers count] > 0) {
    TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                    @"Checking %d controllers for garbage.", [controllers count]);

    NSSet* fullControllerList = [controllers copy];
    for (UIViewController* controller in fullControllerList) {

      // Subtract one from the retain count here due to the copied set.
      NSInteger retainCount = [controller retainCount] - 1;

      TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                      @"Retain count for %X is %d", controller, retainCount);

      if (retainCount == 1) {
        [controller unsetProperties];

        // The object's retain count is now 1, so when we release the copied set below,
        // the object will be completely released.
        [controllers removeObject:controller];
      }
    }

    TT_RELEASE_SAFELY(fullControllerList);
  }

  if ([controllers count] == 0) {
    TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                    @"Killing the common garbage collector.");
    [gsGarbageCollectorTimer invalidate];
    TT_RELEASE_SAFELY(gsGarbageCollectorTimer);
    TT_RELEASE_SAFELY(gsCommonControllers);
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)navigatorURL {
  return self.originalNavigatorURL;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)originalNavigatorURL {
  NSString* key = [NSString stringWithFormat:@"%d", self.hash];
  return [gNavigatorURLs objectForKey:key];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOriginalNavigatorURL:(NSString*)URL {
  NSString* key = [NSString stringWithFormat:@"%d", self.hash];
  if (URL) {
    if (!gNavigatorURLs) {
      gNavigatorURLs = [[NSMutableDictionary alloc] init];
    }
    [gNavigatorURLs setObject:URL forKey:key];

    [UIViewController addGlobalController:self];

  } else {
    [gNavigatorURLs removeObjectForKey:key];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary*)frozenState {
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFrozenState:(NSDictionary*)frozenState {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)canContainControllers {
  return NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)superController {
  UIViewController* parent = self.parentViewController;
  if (parent) {
    return parent;
  } else {
    NSString* key = [NSString stringWithFormat:@"%d", self.hash];
    return [gSuperControllers objectForKey:key];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSuperController:(UIViewController*)viewController {
  NSString* key = [NSString stringWithFormat:@"%d", self.hash];
  if (viewController) {
    if (!gSuperControllers) {
      gSuperControllers = TTCreateNonRetainingDictionary();
    }
    [gSuperControllers setObject:viewController forKey:key];

    [UIViewController addGlobalController:self];

  } else {
    [gSuperControllers removeObjectForKey:key];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)topSubcontroller {
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)ttPreviousViewController {
  NSArray* viewControllers = self.navigationController.viewControllers;
  if (viewControllers.count > 1) {
    NSUInteger index = [viewControllers indexOfObject:self];
    if (index != NSNotFound && index > 0) {
      return [viewControllers objectAtIndex:index-1];
    }
  }

  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)nextViewController {
  NSArray* viewControllers = self.navigationController.viewControllers;
  if (viewControllers.count > 1) {
    NSUInteger index = [viewControllers indexOfObject:self];
    if (index != NSNotFound && index+1 < viewControllers.count) {
      return [viewControllers objectAtIndex:index+1];
    }
  }
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)popupViewController {
  NSString* key = [NSString stringWithFormat:@"%d", self.hash];
  return [gPopupViewControllers objectForKey:key];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPopupViewController:(UIViewController*)viewController {
  NSString* key = [NSString stringWithFormat:@"%d", self.hash];
  if (viewController) {
    if (!gPopupViewControllers) {
      gPopupViewControllers = TTCreateNonRetainingDictionary();
    }
    [gPopupViewControllers setObject:viewController forKey:key];

    [UIViewController addGlobalController:self];

  } else {
    [gPopupViewControllers removeObjectForKey:key];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addSubcontroller:(UIViewController*)controller animated:(BOOL)animated
        transition:(UIViewAnimationTransition)transition {
  if (self.navigationController) {
    [self.navigationController addSubcontroller:controller animated:animated
                               transition:transition];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeFromSupercontroller {
  [self removeFromSupercontrollerAnimated:YES];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeFromSupercontrollerAnimated:(BOOL)animated {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:animated];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)bringControllerToFront:(UIViewController*)controller animated:(BOOL)animated {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)keyForSubcontroller:(UIViewController*)controller {
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)subcontrollerForKey:(NSString*)key {
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)persistView:(NSMutableDictionary*)state {
  return YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)restoreView:(NSDictionary*)state {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)persistNavigationPath:(NSMutableArray*)path {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)delayDidEnd {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showBars:(BOOL)show animated:(BOOL)animated {
  [[UIApplication sharedApplication] setStatusBarHidden:!show animated:animated];

  if (animated) {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:TT_TRANSITION_DURATION];
  }
  self.navigationController.navigationBar.alpha = show ? 1 : 0;
  if (animated) {
    [UIView commitAnimations];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dismissModalViewController {
  [self dismissModalViewControllerAnimated:YES];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)canBeTopViewController {
  return YES;
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation UIViewController (TTCategoryInternal)


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)addGlobalController:(UIViewController*)controller {
  // TTViewController calls unsetProperties in its dealloc.
  if (![controller isKindOfClass:[TTViewController class]]) {
    [[UIViewController commonControllers] addObject:controller];

    TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                    @"Adding a global controller.");

    if (nil == gsGarbageCollectorTimer) {
      gsGarbageCollectorTimer =
      [[NSTimer scheduledTimerWithTimeInterval: kGarbageCollectionInterval
                                        target: [UIViewController class]
                                      selector: @selector(doGarbageCollection)
                                      userInfo: nil
                                       repeats: YES] retain];
    }
#if TTDFLAG_CONTROLLERGARBAGECOLLECTION
  } else {
    TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                    @"Not adding a global controller.");
#endif
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unsetProperties {
  TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                  @"Unsetting this controller's properties: %X", self);

  NSString* urlPath = self.originalNavigatorURL;
  if (nil != urlPath) {
    TTDCONDITIONLOG(TTDFLAG_CONTROLLERGARBAGECOLLECTION,
                    @"Removing this URL path: %@", urlPath);

    [[TTNavigator navigator].URLMap removeObjectForURL:urlPath];
    self.originalNavigatorURL = nil;
  }

  self.superController = nil;
  self.popupViewController = nil;
}

@end
