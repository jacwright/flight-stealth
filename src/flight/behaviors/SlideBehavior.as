/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.behaviors
{
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	import flight.data.IRange;
	import flight.data.IScroll;
	import flight.data.Range;
	import flight.events.ButtonEvent;

	public class SlideBehavior extends Behavior// extends StepBehavior
	{
		
//		[Bindable]
		[Binding(target="target.skin.track")]
		public var track:InteractiveObject;
		
//		[Bindable]
		[Binding(target="target.skin.thumb")]
		public var thumb:InteractiveObject;
		
//		[Bindable]
		[Binding(target="target.horizontal")]
		public var horizontal:Boolean = false;
		
//		[Bindable]
		[Binding(target="target.position")]
		public var position:IRange = new Range();		// TODO: implement lazy instantiation of position
		
		
		private var _percent:Number = 0;
		private var dragPercent:Number;
		private var dragPoint:Number;
		private var dragging:Boolean;
		private var forwardPress:Boolean;
		
		public function SlideBehavior(target:InteractiveObject = null)
		{
			super(target);
		}
		
		[Bindable(event="percentChange")]
		public function get percent():Number
		{
			return _percent;
		}
		
		override public function set target(value:InteractiveObject):void
		{
			super.target = value;
			
			if (target == null) {
				return;
			}
			
//			track = getSkinPart("track");
//			thumb = getSkinPart("thumb");
			if (track) { ButtonEvent.initialize(track); }
			if (thumb) { ButtonEvent.initialize(thumb); }
			
			if (track && track.width > track.height) {
				horizontal = true;
			}
			if (track && thumb) {
				updatePosition();
			}
		}
		
		private var _snapThumb:Boolean = false;
		
		[Bindable(event="snapThumbChange")]
		public function get snapThumb():Boolean { return _snapThumb; }
		public function set snapThumb(value:Boolean):void
		{
			_snapThumb = value;
			dispatchEvent(new Event("snapThumbChange"));
		}
		
		[DataListener(target="position.percent")]
		public function onPosition(percent:Number):void
		{
			if (thumb == null || track == null) {
				return;
			}
			
			if (!dragging) {
				_percent = position.percent;
				updatePosition();
				dispatchEvent(new Event("percentChange"));
			}
		}
		
		[EventListener(type="press", target="track")]
		public function onTrackPress(event:ButtonEvent):void
		{
			var size:Number = horizontal ? track.width - thumb.width : track.height - thumb.height;
			var mousePoint:Number = horizontal ? track.parent.mouseX - track.x : track.parent.mouseY - track.y;
			
			if (snapThumb) {
				thumb.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, thumb.mouseX, thumb.mouseY));
				
				_percent = (mousePoint - thumb.width / 2) / size;
				_percent = _percent <= 0 ? 0 : _percent >= 1 ? 1 : _percent;
				position.percent = _percent;
				updatePosition();
				
				dragPoint = horizontal ? thumb.x + thumb.width / 2 : thumb.y + thumb.height / 2;
				dragPercent = _percent;
				
				dispatchEvent(new Event("percentChange"));
			} else {
				forwardPress = mousePoint > ((horizontal ? thumb.width / 2 : thumb.height / 2) + size * position.percent);
				
				var control:IScroll = position as IScroll;
				
				if (control) {
					if (forwardPress) {
						control.pageForward();
					} else {
						control.pageBackward();
					}
				}
			}
			event.updateAfterEvent();
		}
		
		[EventListener(type="hold", target="track")]
		public function onTrackHold(event:ButtonEvent):void
		{
			var size:Number = horizontal ? track.width - thumb.width : track.height - thumb.height;
			var mousePoint:Number = horizontal ? track.parent.mouseX - track.x : track.parent.mouseY - track.y;
			var forwardHold:Boolean = mousePoint > ((horizontal ? thumb.width / 2 : thumb.height / 2) + size * position.percent);
			
			if (forwardPress != forwardHold) {
				return;
			}
			
			var control:IScroll = position as IScroll;
			
			if (control) {
				if (forwardPress) {
					control.pageForward();
				} else {
					control.pageBackward();
				}
			}
			event.updateAfterEvent();
		}
		
		[EventListener(type="press", target="thumb")]
		public function onThumbPress(event:ButtonEvent):void
		{
			dragging = true;
			dragPoint = horizontal ? thumb.parent.mouseX : thumb.parent.mouseY;
			dragPercent = _percent;
		}
		
		[EventListener(type="drag", target="thumb")]
		public function onThumbDrag(event:ButtonEvent):void
		{
			var mousePoint:Number = horizontal ? thumb.parent.mouseX : thumb.parent.mouseY;
			var size:Number = horizontal ? track.width - thumb.width : track.height - thumb.height;
			var delta:Number = (mousePoint - dragPoint) / size;
			_percent = dragPercent + delta;
			_percent = _percent <= 0 ? 0 : (_percent >= 1 ? 1 : _percent);
			position.percent = _percent;
			updatePosition();
			dispatchEvent(new Event("percentChange"));
			
			event.updateAfterEvent();
		}
		
		[EventListener(type="release", target="thumb")]
		[EventListener(type="releaseOutside", target="thumb")]
		public function onThumbRelease(event:ButtonEvent):void
		{
			dragging = false;
		}
		
		[DataListener(target="target.width")]
		[DataListener(target="target.height")]
		public function onResize(size:Number):void
		{
			// TODO: refactor to commit properties
			updatePosition();
		}
		
		
		public function updatePosition():void
		{
			if (track && thumb) {
				var p:Point = new Point();
				
				if (horizontal) {
					p.x = (track.width - thumb.width) * _percent + track.x;
					p = thumb.parent.globalToLocal(track.parent.localToGlobal(p));
					thumb.x = Math.round(p.x);
				} else {
//					var trackHeight:Number = resolveHeight(track);
//					var thumbHeight:Number = resolveHeight(thumb);
//					p.y = (trackHeight - thumbHeight) * _percent + track.y;
					p = thumb.parent.globalToLocal(track.parent.localToGlobal(p));
					thumb.y = Math.round(p.y);
				}
			}
		}
		
	}
}
