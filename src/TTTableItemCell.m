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

#import "Three20/TTTableItemCell.h"

#import "Three20/TTGlobalCore.h"
#import "Three20/TTGlobalUI.h"

#import "Three20/TTTableItem.h"
#import "Three20/TTImageView.h"
#import "Three20/TTStyledTextLabel.h"
#import "Three20/TTActivityLabel.h"
#import "Three20/TTTextEditor.h"
#import "Three20/TTURLMap.h"
#import "Three20/TTNavigator.h"
#import "Three20/TTURLCache.h"
#import "Three20/TTDefaultStyleSheet.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

static const CGFloat kVPadding = 10;
static const CGFloat kMargin = 10;
static const CGFloat kCellBorderSize = 1;
static const CGFloat kSmallMargin = 6;
static const CGFloat kSpacing = 8;
static const CGFloat kControlPadding = 8;
static const CGFloat kDefaultTextViewLines = 5;
static const CGFloat kMoreButtonMargin = 40;

static const CGFloat kKeySpacing = 12;

static const CGFloat kKeyWidth = 75;
static const CGFloat kMaxLabelHeight = 2000;

// There is an odd issue with the height we return for rowHeight being slightly shorter than
// the height the content view ends up being.
static const NSInteger kExtraVerticalHeight = 1;

static const NSInteger kMessageTextLineCount = 2;

static const CGFloat kDefaultImageSize = 50;
static const CGFloat kDefaultMessageImageWidth = 34;
static const CGFloat kDefaultMessageImageHeight = 34;


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableLinkedItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (void)dealloc {
  TT_RELEASE_SAFELY(_item);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (id)object {
  return _item;
}

- (void)setObject:(id)object {
  if (_item != object) {
    // We've just ensured that _item != object, so a release/retain is fine here.
    [_item release];
    _item = [object retain];

    TTTableLinkedItem* item = object;

    // accessoryURL takes priority over URL when setting the accessory type because
    // you can still access URL by tapping the row if there is an accessory button.
    if (nil != item.accessoryURL) {
      self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

    } else if (nil != item.URL) {
      TTNavigationMode navigationMode = [[TTNavigator navigator].URLMap
        navigationModeForURL:item.URL];

      if (navigationMode == TTNavigationModeCreate ||
          navigationMode == TTNavigationModeShare) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      } else {
        self.accessoryType = UITableViewCellAccessoryNone;
      }
    }

    // Any URL can be tapped and accessed.
    if (nil != item.URL) {
      self.selectionStyle = TTSTYLEVAR(tableSelectionStyle);
    } else {
      self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (nil == item.URL && nil == item.accessoryURL) {
      self.accessoryType = UITableViewCellAccessoryNone;
      self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
  }
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableTitleItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    self.textLabel.font                 = TTSTYLEVAR(tableTitleFont);
    self.textLabel.textColor            = TTSTYLEVAR(tableTitleColor);
    self.textLabel.highlightedTextColor = TTSTYLEVAR(tableTitleHighlightedColor);
    self.textLabel.lineBreakMode        = TTSTYLEVAR(tableTitleLineBreakMode);
    self.textLabel.numberOfLines        = TTSTYLEVAR(tableTitleNumberOfLines);
    self.textLabel.textAlignment        = TTSTYLEVAR(tableTitleTextAlignment);
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];

  self.textLabel.frame = CGRectInset(self.contentView.bounds, kHPadding, kVPadding);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (CGFloat)rowHeightWithTableView:(UITableView*)tableView {
  CGFloat contentWidth = [self contentWidthWithTableView:tableView];
  CGFloat height = [self.textLabel heightWithWidth:contentWidth];
  return height + kVPadding*2;
}

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableTitleItem* item = object;
    self.textLabel.text = item.title;
  }  
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableCaptionItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
    self.textLabel.font                      = TTSTYLEVAR(tableCaptionFont);
    self.textLabel.textColor                 = TTSTYLEVAR(tableCaptionColor);
    self.textLabel.highlightedTextColor      = TTSTYLEVAR(tableCaptionHighlightedColor);
    self.textLabel.lineBreakMode             = TTSTYLEVAR(tableCaptionLineBreakMode);
    self.textLabel.numberOfLines             = TTSTYLEVAR(tableCaptionNumberOfLines);
    self.textLabel.textAlignment             = TTSTYLEVAR(tableCaptionTextAlignment);
    self.textLabel.adjustsFontSizeToFitWidth = TTSTYLEVAR(tableCaptionAdjustsFontSizeToFitWidth);
    self.textLabel.minimumFontSize           = TTSTYLEVAR(tableCaptionMinimumFontSize);

    self.detailTextLabel.font                 = TTSTYLEVAR(tableCaptionTitleFont);
    self.detailTextLabel.textColor            = TTSTYLEVAR(tableCaptionTitleColor);
    self.detailTextLabel.highlightedTextColor = TTSTYLEVAR(tableCaptionTitleHighlightedColor);
    self.detailTextLabel.lineBreakMode        = TTSTYLEVAR(tableCaptionTitleLineBreakMode);
    self.detailTextLabel.numberOfLines        = TTSTYLEVAR(tableCaptionTitleNumberOfLines);
    self.detailTextLabel.textAlignment        = TTSTYLEVAR(tableCaptionTitleTextAlignment);
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat captionWidth = kKeyWidth;
  CGFloat captionHeight = MIN(
    self.contentView.height - kVPadding * 2,
    [self.textLabel heightWithWidth:captionWidth]);

  CGFloat titleWidth = self.contentView.width - (kKeyWidth + kKeySpacing + kHPadding * 2);
  CGFloat titleHeight = MIN(
    self.contentView.height - kVPadding * 2,
    [self.detailTextLabel heightWithWidth:titleWidth]);

  self.textLabel.frame = CGRectMake(kHPadding, kVPadding,
                                    captionWidth, captionHeight);

  self.detailTextLabel.frame = CGRectMake(kHPadding + kKeyWidth + kKeySpacing, kVPadding,
                                          titleWidth, titleHeight);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (CGFloat)rowHeightWithTableView:(UITableView*)tableView {
  CGFloat contentWidth = [self contentWidthWithTableView:tableView];

  CGFloat captionWidth = kKeyWidth;
  CGFloat captionHeight = [self.textLabel heightWithWidth:captionWidth];

  CGFloat titleWidth = contentWidth - (kKeyWidth + kKeySpacing);
  CGFloat titleHeight = [self.detailTextLabel heightWithWidth:titleWidth];

  return MAX(captionHeight, titleHeight) + kVPadding * 2;
}

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableCaptionItem* item = object;
    self.textLabel.text = item.caption;
    self.detailTextLabel.text = item.title;
  }  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (UILabel*)captionLabel {
  return self.textLabel;
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableSubtitleItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
    self.textLabel.font                 = TTSTYLEVAR(tableTitleFont);
    self.textLabel.textColor            = TTSTYLEVAR(tableTitleColor);
    self.textLabel.highlightedTextColor = TTSTYLEVAR(tableTitleHighlightedColor);
    self.textLabel.lineBreakMode        = TTSTYLEVAR(tableTitleLineBreakMode);
    self.textLabel.numberOfLines        = TTSTYLEVAR(tableTitleNumberOfLines);
    self.textLabel.textAlignment        = TTSTYLEVAR(tableTitleTextAlignment);

    self.detailTextLabel.font                 = TTSTYLEVAR(tableSubtitleFont);
    self.detailTextLabel.textColor            = TTSTYLEVAR(tableSubtitleColor);
    self.detailTextLabel.highlightedTextColor = TTSTYLEVAR(tableSubtitleHighlightedColor);
    self.detailTextLabel.lineBreakMode        = TTSTYLEVAR(tableSubtitleLineBreakMode);
    self.detailTextLabel.numberOfLines        = TTSTYLEVAR(tableSubtitleNumberOfLines);
    self.detailTextLabel.textAlignment        = TTSTYLEVAR(tableSubtitleTextAlignment);
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat width = self.contentView.width - kHPadding * 2;
  const CGFloat paddedCellHeight = self.contentView.height - kVPadding * 2;

  CGFloat titleHeight = [self.textLabel heightWithWidth:width];
  CGFloat subtitleHeight = [self.detailTextLabel heightWithWidth:width];

  CGFloat height = titleHeight + subtitleHeight;

  if (height > paddedCellHeight) {
    // Likely a fixed-height cell. We want to show both bits of information, so let's see how
    // much we can fit.
    
    NSInteger maxTitleRows = 0;
    NSInteger maxSubtitleRows = 0;
    if (self.textLabel.font.lineHeight > 0) {
      maxTitleRows = (NSInteger)floor(paddedCellHeight / self.textLabel.font.lineHeight);
    }
    if (maxTitleRows > 0 && self.detailTextLabel.font.lineHeight > 0) {
      // Prioritize the title, but attempt to show at least one subtitle
      // We could use similar logic to prioritize the subtitle.
      while (0 == maxSubtitleRows && maxTitleRows > 0) {
        CGFloat remainingCellHeight = paddedCellHeight -
          maxTitleRows * self.textLabel.font.lineHeight;
        maxSubtitleRows = (NSInteger)floor(
          remainingCellHeight / self.detailTextLabel.font.lineHeight);

        if (0 == maxSubtitleRows) {
          maxTitleRows--;
        }
      }

      if (0 == maxSubtitleRows && 0 == maxTitleRows) {
        // There's not enough room to show both a title and a subtitle; just show the title then
        titleHeight = paddedCellHeight;
        subtitleHeight = 0;
      }
    }
  }

  self.textLabel.frame = CGRectMake(kHPadding, kVPadding,
                                    width, titleHeight);

  self.detailTextLabel.frame = CGRectMake(kHPadding, kVPadding + titleHeight,
                                          width, subtitleHeight);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (CGFloat)rowHeightWithTableView:(UITableView*)tableView {
  CGFloat contentWidth = [self contentWidthWithTableView:tableView];
  CGFloat titleHeight = [self.textLabel heightWithWidth:contentWidth];
  CGFloat subtitleHeight = [self.detailTextLabel heightWithWidth:contentWidth];
  return titleHeight + subtitleHeight + kVPadding * 2 + kExtraVerticalHeight;
}

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableSubtitleItem* item = object;
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.subtitle;
  }  
}

@end

/* TODO: CLEANUP
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableSubtextItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  TTTableCaptionItem* item = object;

  CGFloat width = tableView.width - kHPadding*2;

  CGSize detailTextSize = [item.text sizeWithFont:TTSTYLEVAR(tableFont)
                                     constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                     lineBreakMode:UILineBreakModeTailTruncation];

  CGSize textSize = [item.caption sizeWithFont:TTSTYLEVAR(font)
                                  constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                  lineBreakMode:UILineBreakModeWordWrap];
  
  return kVPadding*2 + detailTextSize.height + textSize.height;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
    self.detailTextLabel.font = TTSTYLEVAR(tableFont);
    self.detailTextLabel.textColor = TTSTYLEVAR(textColor);
    self.detailTextLabel.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
    self.detailTextLabel.adjustsFontSizeToFitWidth = YES;

    self.textLabel.font = TTSTYLEVAR(font);
    self.textLabel.textColor = TTSTYLEVAR(tableSubTextColor);
    self.textLabel.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
    self.textLabel.textAlignment = UITextAlignmentLeft;
    self.textLabel.contentMode = UIViewContentModeTop;
    self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.textLabel.numberOfLines = 0;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
    
  if (!self.textLabel.text.length) {
    CGFloat titleHeight = self.textLabel.height + self.detailTextLabel.height;
    
    [self.detailTextLabel sizeToFit];
    self.detailTextLabel.top = floor(self.contentView.height/2 - titleHeight/2);
    self.detailTextLabel.left = self.detailTextLabel.top*2;
  } else {
    [self.detailTextLabel sizeToFit];
    self.detailTextLabel.left = kHPadding;
    self.detailTextLabel.top = kVPadding;
    
    CGFloat maxWidth = self.contentView.width - kHPadding*2;
    CGSize captionSize =
      [self.textLabel.text sizeWithFont:self.textLabel.font
                                 constrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                 lineBreakMode:self.textLabel.lineBreakMode];
    self.textLabel.frame = CGRectMake(kHPadding, self.detailTextLabel.bottom,
                                      captionSize.width, captionSize.height);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableCaptionItem* item = object;
    self.textLabel.text = item.caption;
    self.detailTextLabel.text = item.text;
  }  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (UILabel*)captionLabel {
  return self.textLabel;
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableMessageItemCell

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  // XXXjoe Compute height based on font sizes
  return 90;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
    _titleLabel = nil;
    _timestampLabel = nil;
    _imageView2 = nil;

    self.textLabel.font = TTSTYLEVAR(font);
    self.textLabel.textColor = TTSTYLEVAR(textColor);
    self.textLabel.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
    self.textLabel.textAlignment = UITextAlignmentLeft;
    self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.contentMode = UIViewContentModeLeft;
    
    self.detailTextLabel.font = TTSTYLEVAR(font);
    self.detailTextLabel.textColor = TTSTYLEVAR(tableSubTextColor);
    self.detailTextLabel.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
    self.detailTextLabel.textAlignment = UITextAlignmentLeft;
    self.detailTextLabel.contentMode = UIViewContentModeTop;
    self.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
    self.detailTextLabel.numberOfLines = kMessageTextLineCount;
    self.detailTextLabel.contentMode = UIViewContentModeLeft;
	}
	return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_titleLabel);
  TT_RELEASE_SAFELY(_timestampLabel);
  TT_RELEASE_SAFELY(_imageView2);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)prepareForReuse {
    [super prepareForReuse];
    [_imageView2 unsetImage];
    _titleLabel.text = nil;
    _timestampLabel.text = nil;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat left = 0;
  if (_imageView2) {
    _imageView2.frame = CGRectMake(kSmallMargin, kSmallMargin,
                                  kDefaultMessageImageWidth, kDefaultMessageImageHeight);
    left += kSmallMargin + kDefaultMessageImageHeight + kSmallMargin;
  } else {
    left = kMargin;
  }

  CGFloat width = self.contentView.width - left;
  CGFloat top = kSmallMargin;
  
  if (_titleLabel.text.length) {
    _titleLabel.frame = CGRectMake(left, top, width, _titleLabel.font.ttLineHeight);
    top += _titleLabel.height;
  } else {
    _titleLabel.frame = CGRectZero;
  }
  
  if (self.captionLabel.text.length) {
    self.captionLabel.frame = CGRectMake(left, top, width, self.captionLabel.font.ttLineHeight);
    top += self.captionLabel.height;
  } else {
    self.captionLabel.frame = CGRectZero;
  }
  
  if (self.detailTextLabel.text.length) {
    CGFloat textHeight = self.detailTextLabel.font.ttLineHeight * kMessageTextLineCount;
    self.detailTextLabel.frame = CGRectMake(left, top, width, textHeight);
  } else {
    self.detailTextLabel.frame = CGRectZero;
  }
  
  if (_timestampLabel.text.length) {
    _timestampLabel.alpha = !self.showingDeleteConfirmation;
    [_timestampLabel sizeToFit];
    _timestampLabel.left = self.contentView.width - (_timestampLabel.width + kSmallMargin);
    _timestampLabel.top = _titleLabel.top;
    _titleLabel.width -= _timestampLabel.width + kSmallMargin*2;
  } else {
    _titleLabel.frame = CGRectZero;
  }
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    _imageView2.backgroundColor = self.backgroundColor;
    _titleLabel.backgroundColor = self.backgroundColor;
    _timestampLabel.backgroundColor = self.backgroundColor;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableMessageItem* item = object;
    if (item.title.length) {
      self.titleLabel.text = item.title;
    }
    if (item.caption.length) {
      self.captionLabel.text = item.caption;
    }
    if (item.text.length) {
      self.detailTextLabel.text = item.text;
    }
    if (item.timestamp) {
      self.timestampLabel.text = [item.timestamp formatShortTime];
    }
    if (item.imageURL) {
      self.imageView2.urlPath = item.imageURL;
    }
  }  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (UILabel*)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.highlightedTextColor = [UIColor whiteColor];
    _titleLabel.font = TTSTYLEVAR(tableFont);
    _titleLabel.contentMode = UIViewContentModeLeft;
    [self.contentView addSubview:_titleLabel];
  }
  return _titleLabel;
}

- (UILabel*)captionLabel {
  return self.textLabel;
}

- (UILabel*)timestampLabel {
  if (!_timestampLabel) {
    _timestampLabel = [[UILabel alloc] init];
    _timestampLabel.font = TTSTYLEVAR(tableTimestampFont);
    _timestampLabel.textColor = TTSTYLEVAR(timestampTextColor);
    _timestampLabel.highlightedTextColor = [UIColor whiteColor];
    _timestampLabel.contentMode = UIViewContentModeLeft;
    [self.contentView addSubview:_timestampLabel];
  }
  return _timestampLabel;
}

- (TTImageView*)imageView2 {
  if (!_imageView2) {
    _imageView2 = [[TTImageView alloc] init];
//    _imageView2.defaultImage = TTSTYLEVAR(personImageSmall);
//    _imageView2.style = TTSTYLE(threadActorIcon);
    [self.contentView addSubview:_imageView2];
  }
  return _imageView2;
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableMoreButtonCell

@synthesize animating = _animating;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  CGFloat height = [super tableView:tableView rowHeightForObject:object];
  CGFloat minHeight = TT_ROW_HEIGHT*1.5;
  if (height < minHeight) {
    return minHeight;
  } else {
    return height;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier]) {
    self.textLabel.font = TTSTYLEVAR(tableSmallFont);
    
    _animating = NO;
    _activityIndicatorView = nil;
  }
  return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_activityIndicatorView);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  
  _activityIndicatorView.left = kMoreButtonMargin - (_activityIndicatorView.width + kSmallMargin);
  _activityIndicatorView.top = floor(self.contentView.height/2 - _activityIndicatorView.height/2);

  self.textLabel.frame = CGRectMake(kMoreButtonMargin, self.textLabel.top,
                                    self.contentView.width - (kMoreButtonMargin + kSmallMargin),
                                    self.textLabel.height);
  self.detailTextLabel.frame = CGRectMake(kMoreButtonMargin, self.detailTextLabel.top,
                                          self.contentView.width - (kMoreButtonMargin + kSmallMargin),
                                          self.detailTextLabel.height);

}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];

    TTTableMoreButton* item = object;
    self.animating = item.isLoading;

    self.textLabel.textColor = TTSTYLEVAR(moreLinkTextColor);
    self.selectionStyle = TTSTYLEVAR(tableSelectionStyle);
  }  
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (UIActivityIndicatorView*)activityIndicatorView {
  if (!_activityIndicatorView) {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
      UIActivityIndicatorViewStyleGray];
    [self.contentView addSubview:_activityIndicatorView];
  }
  return _activityIndicatorView;
}

- (void)setAnimating:(BOOL)animating {
  if (_animating != animating) {
    _animating = animating;
    
    if (_animating) {
      [self.activityIndicatorView startAnimating];
    } else {
      [_activityIndicatorView stopAnimating];
    }
    [self setNeedsLayout];
  }
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableImageItemCell

@synthesize imageView2 = _imageView2;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  TTTableImageItem* imageItem = object;

  UIImage* image = imageItem.imageURL
    ? [[TTURLCache sharedCache] imageForURL:imageItem.imageURL] : nil;
  if (!image) {
    image = imageItem.defaultImage;
  }
  
  CGFloat imageHeight, imageWidth;
  TTImageStyle* style = [imageItem.imageStyle firstStyleOfClass:[TTImageStyle class]];
  if (style && !CGSizeEqualToSize(style.size, CGSizeZero)) {
    imageWidth = style.size.width + kKeySpacing;
    imageHeight = style.size.height;
  } else {
    imageWidth = image
      ? image.size.width + kKeySpacing
      : (imageItem.imageURL ? kDefaultImageSize + kKeySpacing : 0);
    imageHeight = image
      ? image.size.height
      : (imageItem.imageURL ? kDefaultImageSize : 0);
  }
  
  CGFloat maxWidth = tableView.width - (imageWidth + kHPadding*2 + kMargin*2);

  CGSize textSize = [imageItem.text sizeWithFont:TTSTYLEVAR(tableSmallFont)
    constrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
    lineBreakMode:UILineBreakModeTailTruncation];

  CGFloat contentHeight = textSize.height > imageHeight ? textSize.height : imageHeight;
  return contentHeight + kVPadding*2;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _imageView2 = [[TTImageView alloc] init];
    [self.contentView addSubview:_imageView2];
	}
	return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_imageView2);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];

  TTTableImageItem* item = self.object;
  UIImage* image = item.imageURL ? [[TTURLCache sharedCache] imageForURL:item.imageURL] : nil;
  if (!image) {
    image = item.defaultImage;
  }

  if ([_item isKindOfClass:[TTTableRightImageItem class]]) {
    CGFloat imageWidth = image
      ? image.size.width
      : (item.imageURL ? kDefaultImageSize : 0);
    CGFloat imageHeight = image
      ? image.size.height
      : (item.imageURL ? kDefaultImageSize : 0);
    
    if (_imageView2.urlPath) {
      CGFloat innerWidth = self.contentView.width - (kHPadding*2 + imageWidth + kKeySpacing);
      CGFloat innerHeight = self.contentView.height - kVPadding*2;
      self.textLabel.frame = CGRectMake(kHPadding, kVPadding, innerWidth, innerHeight);

      _imageView2.frame = CGRectMake(self.textLabel.right + kKeySpacing,
                                     floor(self.height/2 - imageHeight/2), imageWidth, imageHeight);
    } else {
      self.textLabel.frame = CGRectInset(self.contentView.bounds, kHPadding, kVPadding);
      _imageView2.frame = CGRectZero;
    }
  } else {
    if (_imageView2.urlPath) {
        CGFloat iconWidth = image
          ? image.size.width
          : (item.imageURL ? kDefaultImageSize : 0);
        CGFloat iconHeight = image
          ? image.size.height
          : (item.imageURL ? kDefaultImageSize : 0);

      TTImageStyle* style = [item.imageStyle firstStyleOfClass:[TTImageStyle class]];
      if (style) {
        _imageView2.contentMode = style.contentMode;
        _imageView2.clipsToBounds = YES;
        _imageView2.backgroundColor = [UIColor clearColor];
        if (style.size.width) {
          iconWidth = style.size.width;
        }
        if (style.size.height) {
          iconHeight = style.size.height;
        }
      }

      _imageView2.frame = CGRectMake(kHPadding, floor(self.height/2 - iconHeight/2),
                                   iconWidth, iconHeight);
      
      CGFloat innerWidth = self.contentView.width - (kHPadding*2 + iconWidth + kKeySpacing);
      CGFloat innerHeight = self.contentView.height - kVPadding*2;
      self.textLabel.frame = CGRectMake(kHPadding + iconWidth + kKeySpacing, kVPadding,
                                        innerWidth, innerHeight);
    } else {
      self.textLabel.frame = CGRectInset(self.contentView.bounds, kHPadding, kVPadding);
      _imageView2.frame = CGRectZero;
    }
  }
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    _imageView2.backgroundColor = self.backgroundColor;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];
  
    TTTableImageItem* item = object;
    _imageView2.style = item.imageStyle;
    _imageView2.defaultImage = item.defaultImage;
    _imageView2.urlPath = item.imageURL;

    if ([_item isKindOfClass:[TTTableRightImageItem class]]) {
      self.textLabel.font = TTSTYLEVAR(tableSmallFont);
      self.textLabel.textAlignment = UITextAlignmentCenter;
      self.accessoryType = UITableViewCellAccessoryNone;
    } else {
      self.textLabel.font = TTSTYLEVAR(tableFont);
      self.textLabel.textAlignment = UITextAlignmentLeft;
    }
  }  
}
@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableActivityItemCell

@synthesize activityLabel = _activityLabel;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _activityLabel = [[TTActivityLabel alloc] initWithStyle:TTActivityLabelStyleGray];
    [self.contentView addSubview:_activityLabel];

    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_activityLabel);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  
  UITableView* tableView = (UITableView*)self.superview;
  if (tableView.style == UITableViewStylePlain) {
    _activityLabel.frame = self.contentView.bounds;
  } else {
    _activityLabel.frame = CGRectInset(self.contentView.bounds, -1, -1);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [_item release];
    _item = [object retain];
  
    TTTableActivityItem* item = object;
    _activityLabel.text = item.text;
  }  
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTStyledTextTableItemCell

@synthesize label = _label;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  TTTableStyledTextItem* item = object;
  if (!item.text.font) {
    item.text.font = TTSTYLEVAR(font);
  }
  
  CGFloat padding = [tableView tableCellMargin]*2 + item.padding.left + item.padding.right;
  if (item.URL) {
    padding += kDisclosureIndicatorWidth;
  }
  
  item.text.width = tableView.width - padding;
  
  return item.text.height + item.padding.top + item.padding.bottom;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _label = [[TTStyledTextLabel alloc] init];
    _label.contentMode = UIViewContentModeLeft;
    [self.contentView addSubview:_label];
  }
  return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_label);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  
  TTTableStyledTextItem* item = self.object;
  _label.frame = CGRectOffset(self.contentView.bounds, item.margin.left, item.margin.top);
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    _label.backgroundColor = self.backgroundColor;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (void)setObject:(id)object {
  if (_item != object) {
    [super setObject:object];
    
    TTTableStyledTextItem* item = object;
    _label.text = item.text;
    _label.contentInset = item.padding;
    [self setNeedsLayout];
  }  
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTStyledTextTableCell

@synthesize label = _label;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  TTStyledText* text = object;
  if (!text.font) {
    text.font = TTSTYLEVAR(font);
  }
  text.width = tableView.width - [tableView tableCellMargin]*2;
  return text.height;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _label = [[TTStyledTextLabel alloc] init];
    _label.contentMode = UIViewContentModeLeft;
    [self.contentView addSubview:_label];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_label);
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  _label.frame = self.contentView.bounds;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    _label.backgroundColor = self.backgroundColor;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (id)object {
  return _label.text;
}

- (void)setObject:(id)object {
  if (self.object != object) {
    _label.text = object;
  }  
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableControlCell

@synthesize item = _item, control = _control;

///////////////////////////////////////////////////////////////////////////////////////////////////
// class private

+ (BOOL)shouldConsiderControlIntrinsicSize:(UIView*)view {
  return [view isKindOfClass:[UISwitch class]];
}

+ (BOOL)shouldSizeControlToFit:(UIView*)view {
  return [view isKindOfClass:[UITextView class]]
         || [view isKindOfClass:[TTTextEditor class]];
}

+ (BOOL)shouldRespectControlPadding:(UIView*)view {
  return [view isKindOfClass:[UITextField class]];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  UIView* view = nil;

  if ([object isKindOfClass:[UIView class]]) {
    view = object;
  } else {
    TTTableControlItem* controlItem = object;
    view = controlItem.control;
  }
  
  CGFloat height = view.height;
  if (!height) {
    if ([view isKindOfClass:[UITextView class]]) {
      UITextView* textView = (UITextView*)view;
      CGFloat ttLineHeight = textView.font.ttLineHeight;
      height = ttLineHeight * kDefaultTextViewLines;
    } else if ([view isKindOfClass:[TTTextEditor class]]) {
      TTTextEditor* textEditor = (TTTextEditor*)view;
      CGFloat ttLineHeight = textEditor.font.ttLineHeight;
      height = ttLineHeight * kDefaultTextViewLines;
    } else if ([view isKindOfClass:[UITextField class]]) {
      UITextField* textField = (UITextField*)view;
      CGFloat ttLineHeight = textField.font.ttLineHeight;
      height = ttLineHeight + kSmallMargin*2;
    } else {
      [view sizeToFit];
      height = view.height;
    }
  }
  
  if (height < TT_ROW_HEIGHT) {
    return TT_ROW_HEIGHT;
  } else {
    return height;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _item = nil;
    _control = nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_item);
  TT_RELEASE_SAFELY(_control);
	[super dealloc];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  if ([TTTableControlCell shouldSizeControlToFit:_control]) {
    _control.frame = CGRectInset(self.contentView.bounds, 2, kSpacing/2);
  } else {
    CGFloat minX = kControlPadding;
    CGFloat contentWidth = self.contentView.width - kControlPadding;
    if (![TTTableControlCell shouldRespectControlPadding:_control]) {
      contentWidth -= kControlPadding;
    }
    if (self.textLabel.text.length) {
      CGSize textSize = [self.textLabel sizeThatFits:self.contentView.bounds.size];
      contentWidth -= textSize.width + kSpacing;
      minX += textSize.width + kSpacing;
    }

    if (!_control.height) {
      [_control sizeToFit];
    }
    
    if ([TTTableControlCell shouldConsiderControlIntrinsicSize:_control]) {
      minX += contentWidth - _control.width;
    }
    
    // XXXjoe For some reason I need to re-add the control as a subview or else
    // the re-use of the cell will cause the control to fail to paint itself on occasion
    [self.contentView addSubview:_control];
    _control.frame = CGRectMake(minX, floor(self.contentView.height/2 - _control.height/2),
                                contentWidth, _control.height);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (id)object {
  return _item ? _item : (id)_control;
}

- (void)setObject:(id)object {
  if (object != _control && object != _item) {
    [_control removeFromSuperview];
    TT_RELEASE_SAFELY(_control);
    TT_RELEASE_SAFELY(_item);
    
    if ([object isKindOfClass:[UIView class]]) {
      _control = [object retain];
    } else if ([object isKindOfClass:[TTTableControlItem class]]) {
      _item = [object retain];
      _control = [_item.control retain];
    }
    
    _control.backgroundColor = [UIColor clearColor];
    self.textLabel.text = _item.caption;
    
    if (_control) {
      [self.contentView addSubview:_control];
    }
  }  
}

@end


#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableFlushViewCell

@synthesize item = _item, view = _view;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell class public

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  return TT_ROW_HEIGHT;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
  if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
    _item = nil;
    _view = nil;

    self.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return self;
}

- (void)dealloc {
  TT_RELEASE_SAFELY(_item);
  TT_RELEASE_SAFELY(_view);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  _view.frame = self.contentView.bounds;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewCell

- (id)object {
  return _item ? _item : (id)_view;
}

- (void)setObject:(id)object {
  if (object != _view && object != _item) {
    [_view removeFromSuperview];
    TT_RELEASE_SAFELY(_view);
    TT_RELEASE_SAFELY(_item);
    
    if ([object isKindOfClass:[UIView class]]) {
      _view = [object retain];
    } else if ([object isKindOfClass:[TTTableViewItem class]]) {
      _item = [object retain];
      _view = [_item.view retain];
    }

    [self.contentView addSubview:_view];
  }  
}

@end
*/
