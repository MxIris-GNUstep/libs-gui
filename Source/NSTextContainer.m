/* 
   NSTextContainer.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999
  
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSNotification.h>

@interface NSTextContainer (TextViewObserver)
- (void) _textViewFrameChanged: (NSNotification *)aNotification;
@end

@implementation NSTextContainer (TextViewObserver)

- (void) _textViewFrameChanged: (NSNotification *)aNotification
{
  id		textView;
  NSSize	newSize;
  NSSize	inset;

  if ( _observingFrameChanges )
    {
      textView = [aNotification object];
      newSize = [textView frame].size;
      inset = [textView textContainerInset];

      if ( _widthTracksTextView )
	newSize.width = MAX(newSize.width - (inset.width * 2.0), 0.0);
      if ( _heightTracksTextView )
	newSize.height = MAX(newSize.height - (inset.height * 2.0), 0.0);

      [self setContainerSize: newSize];
    }
}

@end /* NSTextContainer (TextViewObserver) */

@implementation NSTextContainer

+ (void) initialize
{
  if ( self == [NSTextContainer class] )
    [self setVersion: 1];
}

- (id) initWithContainerSize: (NSSize)aSize
{
  NSDebugLLog(@"NSText", @"NSTextContainer initWithContainerSize");
  _layoutManager = nil;
  _textView = nil;
  _containerRect.size = aSize;
  _lineFragmentPadding = 0.0;
  _observingFrameChanges = NO;
  _widthTracksTextView = NO;
  _heightTracksTextView = NO;

  return self;
}

- (void) setLayoutManager: (NSLayoutManager *)aLayoutManager
{
  ASSIGN(_layoutManager, aLayoutManager);
}

- (NSLayoutManager *) layoutManager
{
  return _layoutManager;
}

- (void) replaceLayoutManager: (NSLayoutManager *)newLayoutManager
{
  id		textStorage = [_layoutManager textStorage];
  NSArray	*textContainers = [_layoutManager textContainers]; 
  unsigned	i, count = [textContainers count];

  [textStorage removeLayoutManager: _layoutManager];
  [textStorage addLayoutManager: newLayoutManager];
  [_layoutManager setTextStorage: nil];

  for ( i = 0; i < count; i++ )
    {
      [newLayoutManager addTextContainer: [textContainers objectAtIndex: i]];
      [_layoutManager removeTextContainerAtIndex: i];
    }
}

- (void) setTextView: (NSTextView *)aTextView
{
  if ( _textView )
    {
      [_textView setTextContainer: nil];
      [[NSNotificationCenter defaultCenter] removeObserver: self];
    }

  ASSIGN(_textView, aTextView);

  if ( aTextView )
    {
      [_textView setTextContainer: self];
      [[NSNotificationCenter defaultCenter] addObserver: self
	selector: @selector(_textViewFrameChanged: )
	    name: NSViewFrameDidChangeNotification
	  object: _textView];
    }
}

- (NSTextView *) textView
{
  return _textView;
}

- (void) setContainerSize: (NSSize)aSize
{
  _containerRect = NSMakeRect(0, 0, aSize.width, aSize.height);

  if ( _layoutManager )
    [_layoutManager textContainerChangedGeometry: self];
}

- (NSSize) containerSize
{
  return _containerRect.size;
}

- (void) setWidthTracksTextView: (BOOL)flag
{
  _widthTracksTextView = flag;
  _observingFrameChanges = _widthTracksTextView | _heightTracksTextView;
}

- (BOOL) widthTracksTextView
{
  return _widthTracksTextView;
}

- (void) setHeightTracksTextView: (BOOL)flag
{
  _heightTracksTextView = flag;
  _observingFrameChanges = _widthTracksTextView | _heightTracksTextView;
}

- (BOOL) heightTracksTextView
{
  return _heightTracksTextView;
}

- (void) setLineFragmentPadding: (float)aFloat
{
  _lineFragmentPadding = aFloat;

  if ( _layoutManager )
    [_layoutManager textContainerChangedGeometry: self];
}

- (float) lineFragmentPadding
{
  return _lineFragmentPadding;
}

- (NSRect) lineFragmentRectForProposedRect: (NSRect)proposedRect
			    sweepDirection: (NSLineSweepDirection)sweepDir
			 movementDirection: (NSLineMovementDirection)moveDir
			     remainingRect: (NSRect *)remainingRect;
{
  // line fragment rectangle simply must fit within the container rectangle
  *remainingRect = NSZeroRect;
  return NSIntersectionRect(proposedRect, _containerRect);
}

- (BOOL) isSimpleRectangularTextContainer
{
  // sub-classes may say no; this class always says yes
  return YES;
}

- (BOOL) containsPoint: (NSPoint)aPoint
{
  return NSPointInRect(aPoint, _containerRect);
}

@end /* NSTextContainer */

