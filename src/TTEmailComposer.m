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

#import "Three20/TTEmailComposer.h"

#import "Three20/TTCorePreprocessorMacros.h"
#import "Three20/TTDebug.h"

#import "Three20/TTNavigator.h"

#import <MessageUI/MFMailComposeViewController.h>


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface TTEmailComposer (TTInternal) <MFMailComposeViewControllerDelegate>
@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTEmailComposer (TTInternal)

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark In-app mail composer


////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Display an email composition interface as a modal controller over the given view controller.
 */
+ (void) displayComposerSheetWithEmail: (TTEmail*)email
                      inViewController: (UIViewController*)viewController {
  TTDASSERT(nil != email);
  if (nil == email) {
    return;
  }

  TTDASSERT(nil != viewController); // nil viewController object hasn't been tested.

  MFMailComposeViewController* composer = [[MFMailComposeViewController alloc] init];
  composer.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)[TTEmailComposer class];

  if (nil != email.to) {
    [composer setToRecipients:[NSArray arrayWithObject:email.to]];
  }
  [composer setSubject:email.title];
  [composer setMessageBody:email.body isHTML:email.isHTML];
  
  [viewController presentModalViewController:composer animated:YES];
  TT_RELEASE_SAFELY(composer);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Dismiss the email composition interface when users tap Cancel or Send.
 */
+ (void) mailComposeController: (MFMailComposeViewController*)controller
           didFinishWithResult: (MFMailComposeResult)result
                         error: (NSError*)error {
  [[TTNavigator navigator].visibleViewController dismissModalViewControllerAnimated:YES];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark External mail composer


////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Launch the Mail application on the device.
 */
+ (void) launchMailAppOnDeviceWithEmail:(TTEmail*)email {
  TTDASSERT(nil != email);
  if (nil == email) {
    return;
  }

  NSString* emailURLPath = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
                     email.to, email.title, email.body];
  emailURLPath = [emailURLPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailURLPath]];
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTEmailComposer


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void) composeEmail:(TTEmail*)email inViewController:(UIViewController*)viewController {
  Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));

  if (nil != mailClass && [mailClass canSendMail]) {
    [self displayComposerSheetWithEmail:email inViewController:viewController];

  } else {
    [self launchMailAppOnDeviceWithEmail:email];
  }
}

@end
