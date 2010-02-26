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

#import "Three20/TTTableViewCell.h"

#import "Three20/TTGlobalUI.h"
#import "Three20/TTGlobalStyle.h"

#import "Three20/TTDefaultStyleSheet.h"

const CGFloat kDisclosureIndicatorWidth = 20;
const CGFloat kDetailDisclosureButtonWidth = 33;
const CGFloat kEditingIndentationWidth = 32;
const CGFloat kReorderButtonWidth = 32;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewCell


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)rowHeightWithTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
  return TT_ROW_HEIGHT;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)contentWidthWithTableView: (UITableView*)tableView
                           indexPath: (NSIndexPath*)indexPath
                             padding: (UIEdgeInsets)padding {
  CGFloat width = tableView.width - padding.left - padding.right - [tableView tableCellMargin] * 2;

  if (tableView.editing) {
    UITableViewCellEditingStyle editingStyle;
    if ([tableView.delegate respondsToSelector:
          @selector(tableView:editingStyleForRowAtIndexPath:)]) {
      editingStyle = [tableView.delegate
                            tableView: tableView
        editingStyleForRowAtIndexPath: indexPath];
    } else {
      editingStyle = UITableViewCellEditingStyleDelete;
    }

    BOOL shouldIndent = YES;
    if (editingStyle == UITableViewCellEditingStyleNone &&
        [tableView.delegate respondsToSelector:
          @selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)]) {
      shouldIndent = [tableView.delegate
                                     tableView: tableView
        shouldIndentWhileEditingRowAtIndexPath: indexPath];
    }

    if (shouldIndent) {
      width -= kEditingIndentationWidth;
    }

    BOOL canMoveRow = NO;
    if ([tableView.dataSource respondsToSelector:
          @selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
      canMoveRow = YES;
      if ([tableView.dataSource respondsToSelector:
            @selector(tableView:canMoveRowAtIndexPath:)]) {
        canMoveRow = [tableView.dataSource
                      tableView: tableView
          canMoveRowAtIndexPath: indexPath];
      }

      if (canMoveRow) {
        width -= kReorderButtonWidth;
      }
    }

    if (canMoveRow) {
      width++;
    }

  } else {
    if (self.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
      width -= kDisclosureIndicatorWidth;
    } else if (self.accessoryType == UITableViewCellAccessoryDetailDisclosureButton) {
      width -= kDetailDisclosureButtonWidth;
    }

    if (tableView.style == UITableViewStyleGrouped) {
      width++;
    }
  }

  return width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)contentWidthWithTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
  CGFloat padding = TTSTYLEVAR(tableHPadding);
  return [self contentWidthWithTableView: tableView
                               indexPath: indexPath
                                 padding: UIEdgeInsetsMake(padding, padding, padding, padding)];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)optimizeLabels: (NSArray*)labels
               heights: (NSMutableArray*)calculatedLabelHeights {

  static const NSInteger kMaxNumberOfLabels = 10;

  TTDASSERT([labels count] == [calculatedLabelHeights count]);
  TTDASSERT([labels count] < kMaxNumberOfLabels);
  if ([labels count] >= kMaxNumberOfLabels) {
    return;
  }

  CGFloat height = 0;

  CGFloat labelHeights[kMaxNumberOfLabels];
  CGFloat maxNumberOfLines[kMaxNumberOfLabels];

  for (int ix = 0; ix < [calculatedLabelHeights count]; ++ix) {
    labelHeights[ix] = [[calculatedLabelHeights objectAtIndex:ix] floatValue];
    height += labelHeights[ix];
    UILabel* label = [labels objectAtIndex:ix];
    maxNumberOfLines[ix] = labelHeights[ix] / label.font.ttLineHeight;
  }

  const CGFloat paddedCellHeight =
    self.contentView.height - TTSTYLEVAR(tableVPadding) * 2;

  if (height > paddedCellHeight) {
    NSInteger labelRowCounts[kMaxNumberOfLabels];
    memset(labelRowCounts, 0, sizeof(NSInteger) * kMaxNumberOfLabels);
    memset(labelHeights, 0, sizeof(CGFloat) * kMaxNumberOfLabels);

    height = 0;

    BOOL couldAddAny = YES;
    while (couldAddAny) {
      couldAddAny = NO;

      for (int ix = 0; ix < [labels count]; ++ix) {
        UILabel* label = [labels objectAtIndex:ix];

        if (nil != label.text &&
            (0 == label.numberOfLines && labelRowCounts[ix] < maxNumberOfLines[ix] ||
            labelRowCounts[ix] < label.numberOfLines)) {
          labelRowCounts[ix]++;
          labelHeights[ix] = labelRowCounts[ix] * label.font.ttLineHeight;

          height = 0;
          for (int iy = 0; iy < [labels count]; ++iy) {
            height += labelHeights[iy];
          }

          if (height > paddedCellHeight) {
            labelRowCounts[ix]--;
            labelHeights[ix] = labelRowCounts[ix] * label.font.ttLineHeight;
          } else {
            couldAddAny = YES;
          }
        }
      }
    }

    BOOL anyRows = NO;
    for (int ix = 0; ix < [labels count]; ++ix) {
      if (labelRowCounts[ix] != 0) {
        anyRows = YES;
        break;
      }
    }

    if (!anyRows) {
      labelHeights[0] = paddedCellHeight;
    }

    [calculatedLabelHeights removeAllObjects];
    for (int ix = 0; ix < [labels count]; ++ix) {
      [calculatedLabelHeights addObject:[NSNumber numberWithFloat:labelHeights[ix]]];
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewCell

- (void)prepareForReuse {
  self.object = nil;
  [super prepareForReuse];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (id)object {
  return nil;
}

- (void)setObject:(id)object {
}

@end
