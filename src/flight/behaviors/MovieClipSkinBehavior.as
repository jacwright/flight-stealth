/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.behaviors
{
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.IEventDispatcher;
	
	import flight.data.DataChange;
	
	[SkinState("up")]
	[SkinState("over")]
	[SkinState("down")]
	
	public class MovieClipSkinBehavior extends Behavior
	{
		
		public static const UP:String = "up";
		public static const OVER:String = "over";
		public static const DOWN:String = "down";
		
		private var _currentState:String = UP;
		private var _movieclip:MovieClip;
		
		[Bindable(event="currentStateChange")]
		[Binding(target="target.currentState")]
		public function get currentState():String { return _currentState; }
		public function set currentState(value:String):void
		{
			DataChange.change(this, "currentState", _currentState, _currentState = value);
		}
		
		[Bindable(event="movieclipChange")]
		[Binding(target="target.skin")]
		public function get movieclip():MovieClip { return _movieclip; }
		public function set movieclip(value:MovieClip):void
		{
			DataChange.change(this, "movieclip", _movieclip, _movieclip = value);
		}
		
		public function MovieClipSkinBehavior(target:IEventDispatcher = null)
		{
			super(target);
		}
		
		// ====== Event Listeners ====== //
		
		[DataListener(target="movieclip")]
		public function onMovieClip(object:MovieClip):void
		{
			// trace(object);
		}
		
		[DataListener(target="currentState")]
		public function onState(object:String):void
		{
			if (movieclip) {
				gotoState(movieclip, object);
			}
		}
		
		// we'll update this for animated/play animations later
		private function gotoState(clip:MovieClip, state:String):void
		{
			var frames:Array = clip.currentLabels;
			for each(var label:FrameLabel in frames) {
				if (label.name == state) {
					clip.gotoAndStop(label.frame);
				}
			}
			
			var length:int = clip.numChildren; // recurse (for now)
			for (var i:int = 0; i < length; i++) {
				var child:DisplayObject = clip.getChildAt(i);
				if (child is MovieClip) {
					gotoState(child as MovieClip, state);
				}
			}
		}
		
	}
}
