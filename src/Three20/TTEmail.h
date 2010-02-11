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
 * A builder object used in TTEmailComposer to create the necessary components of an email.
 *
 * Implements the chaining design pattern.
 * Example: [[[TTEmail email] applyTitle:@"Hello world"]
 *                            applyBody:@"This is my email"]
 */
@interface TTEmail : NSObject {
  NSString* _to;
  NSString* _title;
  NSString* _body;
  BOOL      _isHTML;
}

+ (TTEmail*) email;

- (TTEmail*) applyTo:(NSString*)to;
- (TTEmail*) applyTitle:(NSString*)title;
- (TTEmail*) applyBody:(NSString*)body;
- (TTEmail*) applyIsHTML:(BOOL)isHTML;

/**
 * The receiver of this email.
 *
 * @default nil
 */
@property (nonatomic, copy)   NSString* to;

/**
 * The subject line of the email.
 *
 * @default nil
 */
@property (nonatomic, copy)   NSString* title;

/**
 * The body of the email.
 *
 * @default nil
 */
@property (nonatomic, copy)   NSString* body;

/**
 * Whether or not the body content should be treated as HTML.
 *
 * @default NO
 */
@property (nonatomic, assign) BOOL      isHTML;

@end
