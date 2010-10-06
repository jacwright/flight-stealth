/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.display
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	/**
	 * @alpha
	 **/
	public class RenderPhase
	{
		
		private static var rendering:Boolean = false;
		private static var phaseList:Array = [];
		private static var phaseIndex:Object = {};
		private static var displayDepths:Dictionary = new Dictionary(true);
		private static var invalidStages:Dictionary = new Dictionary(true);
		
		public static function registerPhase(type:String, priority:int = 0, ascending:Boolean = true):Boolean
		{
			var phase:RenderPhase;
			if (phaseIndex[type] != null) {
				phase = phaseIndex[type];
				phase.priority = priority;
				phase.ascending = ascending;
			} else {
				phase = new RenderPhase(type, priority, ascending);
				phaseIndex[type] = phase;
				phaseList.push(phase);
			}
			
			phaseList.sortOn("priority", [Array.DESCENDING, Array.NUMERIC]);
			return true;
		}
		
		public static function invalidate(display:DisplayObject, type:String):void
		{
			if (display == null) {
				return;
			}
			
			if (phaseIndex[type] == null) {
				throw new Error("DisplayObject cannot be invalidated in unknown phase '" + type + "'.");
			}
			
			var phase:RenderPhase = phaseIndex[type];
			if (phase.hasDisplay(display)) {
				return;
			}
			
			display.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0xF, true);
			display.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0xF, true);
			
			if (display.stage == null) {
				phase.addDisplay(display, -1);
				return;
			}
			
			var depth:int = displayDepths[display] != null ?
				displayDepths[display] :
				displayDepths[display] = getDepth(display);
			
			phase.addDisplay(display, depth);
			
			if (!rendering) {
				invalidateStage(display.stage);
			} else if ((phase.ascending && depth <= phase.renderingDepth) ||
				(!phase.ascending && depth >= phase.renderingDepth)) {
				setTimeout(invalidateStage, 0, display.stage);
			}
		}
		
		public static function render():void
		{
			rendering = true;
			validateStages();
			for each (var phase:RenderPhase in phaseList) {
				phase.render();
			}
			rendering = false;
		}
		
		private static function getDepth(display:DisplayObject):int
		{
			var depth:int = 0;
			while ((display = display.parent) != null) {
				depth++;
				// if a parent already has depth defined, take the shortcut
				if (displayDepths[display] != null) {
					depth += displayDepths[display];
					break;
				}
			}
			return depth;
		}
		
		private static function invalidateStage(stage:Stage):void
		{
			invalidStages[stage] = true;
			stage.invalidate();
			stage.addEventListener(Event.RENDER, onRender, false, -0xF, true);
			stage.addEventListener(Event.RESIZE, onRender, false, -0xF, true);
		}
		
		private static function validateStages():void
		{
			for (var i:* in invalidStages) {
				var stage:Stage = i;
				stage.removeEventListener(Event.RENDER, onRender);
				stage.removeEventListener(Event.RESIZE, onRender);
			}
		}
		
		private static function onRender(event:Event):void
		{
			render();
		}
		
		private static function onAddedToStage(event:Event):void
		{
			var display:DisplayObject = DisplayObject(event.target);
			displayDepths[display] = getDepth(display);
			
			for each (var phase:RenderPhase in phaseList) {
				if (phase.hasDisplay(display)) {
					phase.removeDisplay(display);
					invalidate(display, phase.type);
				}
			}
		}
		
		private static function onRemovedFromStage(event:Event):void
		{
			var display:DisplayObject = DisplayObject(event.target);
			delete displayDepths[display];
			
			for each (var phase:RenderPhase in phaseList) {
				if (phase.hasDisplay(display)) {
					phase.removeDisplay(display);
					phase.addDisplay(display, -1);
				}
			}
		}
		
		
		public var ascending:Boolean = true;
		public var priority:int = 0;
		
		private var _type:String;
		private var depths:Array = [];
		private var pos:int = -1;
		private var current:Dictionary = new Dictionary(true);
		private var invalidated:Dictionary = new Dictionary(true);
		
		public function RenderPhase(type:String, priority:int = 0, ascending:Boolean = true)
		{
			_type = type;
			this.ascending = ascending;
			this.priority = priority;
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function get renderingDepth():int
		{
			return pos;
		}
		
		public function render():void
		{
			if (depths.length == 0) {
				return;
			}
			
			var beg:int, end:int, vel:int;
			if (ascending) {
				beg = -1;
				end = depths.length;
				vel = 1;
			} else {
				beg = depths.length;
				end = 0;
				vel = -1;
			}
			var pre:Dictionary;
			
			for (pos = beg; pos != end; pos += vel) {
				if (depths[pos] == null) {
					continue;
				}
				
				// replace current dictionary with a clean one before new cycle
				pre = current;
				current = depths[pos];
				depths[pos] = pre;
				
				for (var i:* in current) {
					var display:DisplayObject = i;
					delete current[i];
					delete invalidated[display];
					display.dispatchEvent(new Event(type));
				}
			}
			pos = -1;
		}
		
		public function addDisplay(display:DisplayObject, depth:int):void
		{
			if (depths[depth] == null) {
				depths[depth] = new Dictionary(true);
			}
			depths[depth][display] = true;
			invalidated[display] = depth;
		}
		
		public function removeDisplay(display:DisplayObject):void
		{
			delete depths[ invalidated[display] ][display];
			delete invalidated[display];
		}
		
		public function hasDisplay(display:IEventDispatcher):Boolean
		{
			return invalidated[display] != null;
		}
		
	}
}
