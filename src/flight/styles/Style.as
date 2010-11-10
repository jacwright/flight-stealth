/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.styles
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import flight.data.DataChange;
	import flight.display.RenderPhase;
	import flight.events.StyleEvent;

	[Event(name="styleChange", type="flight.events.StyleEvent")]
	[Event(name="styleDelete", type="flight.events.StyleEvent")]
	
	/**
	 * A style object on which dynamic style data is stored.
	 */
	dynamic public class Style extends Proxy
	{
		/**
		 * The style class that will be used to create new Style objects for each component or stealth display object.
		 * Set a new style class here an any stealth display objects created afterwards will use this type of object as
		 * its style object.
		 */
		public static var styleClass:Class = Style;

		/**
		 * Get a style object for the provided target. This will be of the type styleClass.
		 * 
		 * @param target A display object to be styled.
		 * @return An object which can hook into a style system provided.
		 */
		public static function getFor(target:DisplayObject):Object
		{
			return new styleClass(target);
		}
		
		/**
		 * Reference to the wrapped IEventDispatcher.
		 */
		protected var dispatcher:EventDispatcher;
		
		private var explicitData:Object;
		private var styleData:Object;
		private var styleProps:Array;
		
		public function Style(target:DisplayObject)
		{
			dispatcher = new EventDispatcher();
			explicitData = {};
			styleData = {};
			styleProps = [];
			_target = target;
		}
		
		[Bindable(event="targetChange", style="noEvent")]
		public function get target():DisplayObject { return _target }
		public function set target(value:DisplayObject):void
		{
			DataChange.change(this, "target", _target, _target = value);
		}
		private var _target:DisplayObject;
		
		override flash_proxy function getProperty(name:*):*
		{
			var prop:String = name.localName;
			return prop in explicitData ? explicitData[prop] : styleData[prop];
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var prop:String = name.localName;
			if (explicitData[prop] != value) {
				if (!styleProps["$"+prop]) {
					styleProps["$"+prop] = true;
					styleProps.push(prop);
				}
				RenderPhase.invalidate(_target, StylePhase.STYLE);
				var oldValue:Object = prop in explicitData ? explicitData[prop] : styleData[prop];
				DataChange.change(this, prop, oldValue, explicitData[name.localName] = value);
				if (hasEventListener(StyleEvent.STYLE_CHANGE)) {
					dispatchEvent(new StyleEvent(StyleEvent.STYLE_CHANGE, false, false, _target, prop, oldValue, value));
				}
			}
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			var prop:String = name.localName;
			return prop in explicitData || prop in styleData;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			var prop:String = name.localName;
			if (!(prop in styleData)) {
				delete styleProps["$"+prop];
				styleProps.splice(styleProps.indexOf(prop), 1);
			}
			RenderPhase.invalidate(_target, StylePhase.STYLE);
			var oldValue:Object = explicitData[prop];
			DataChange.queue(this, prop, oldValue, styleData[prop]);
			var deleted:Boolean = delete explicitData[prop];
			if (hasEventListener(StyleEvent.STYLE_CHANGE)) {
				dispatchEvent(new StyleEvent(StyleEvent.STYLE_CHANGE, false, false, _target, prop, oldValue, styleData[prop]));
			}
			return deleted;
		}
		
		override flash_proxy function nextName(index:int):String
		{
			return String(styleProps[index - 1]);
		}
		
		override flash_proxy function nextValue(index:int):*
		{
			var prop:String = styleProps[index - 1];
			return prop in explicitData ? explicitData[prop] : styleData[prop];
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			return (index + 1) % (styleProps.length + 1);
		}
		
		// ========== Dispatcher Methods ========== //
		
		/**
		 * Registers an event listener object with an EventDispatcher object so
		 * that the listener receives notification of an event. You can register
		 * event listeners on all nodes in the display list for a specific type
		 * of event, phase, and priority.
		 * 
		 * @param	type				The type of event.
		 * @param	listener			The listener function that processes the
		 * 								event.
		 * @param	useCapture			Determines whether the listener works in
		 * 								the capture phase or the target and
		 * 								bubbling phases.
		 * @param	priority			The priority level of the event
		 * 								listener.
		 * @param	useWeakReference	Determines whether the reference to the
		 * 								listener is strong or weak.
		 * 
		 * @see		flash.events.EventDispatcher#addEventListener
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * Removes a listener from the Dispatcher object. If there is no
		 * matching listener registered with the Dispatcher object, a call
		 * to this method has no effect.
		 * 
		 * @param	type				The type of event.
		 * @param	listener			The listener object to remove.
		 * @param	useCapture			Specifies whether the listener was
		 * 								registered for the capture phase or the
		 * 								target and bubbling phases.
		 * 
		 * @see		flash.events.EventDispatcher#removeEventListener
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * Dispatches an event into the event flow, but only if there is a
		 * registered listener. If the generic Event object is all that is 
		 * required the dispatch() method is recommended.
		 * 
		 * @param	event				The Event object that is dispatched into
		 * 								the event flow.
		 * 
		 * @return						A value of true if the event was
		 * 								successfully dispatched.
		 *  
		 * @see		flash.events.EventDispatcher#dispatchEvent
		 * @see		flight.events.Dispatcher#dispatch
		 */
		public function dispatchEvent(event:Event):Boolean
		{
			return dispatcher.dispatchEvent(event);
		}
		
		/**
		 * Checks whether the Dispatcher object has any listeners
		 * registered for a specific type of event. This check is made before
		 * any events are dispatched.
		 * 
		 * @param	type				The type of event.
		 * 
		 * @return						A value of true if a listener of the
		 * 								specified type is registered; false
		 * 								otherwise.
		 * 
		 * @see		flight.events.EventDispatcher#hasEventListener
		 */
		public function hasEventListener(type:String):Boolean
		{
			return dispatcher.hasEventListener(type);
		}
		
		/**
		 * Checks whether an event listener is registered with this
		 * Dispatcher object or any of its ancestors for the specified
		 * event type. Because ancesry is only available through the display
		 * list, this method behaves identically to hasEventListener().
		 * 
		 * @param	type				The type of event.
		 * 
		 * @return						A value of true if a listener of the
		 * 								specified type will be triggered; false
		 * 								otherwise.
		 * 
		 * @see		flight.events.EventDispatcher#willTrigger
		 */
		public function willTrigger(type:String):Boolean
		{
			return dispatcher.willTrigger(type);
		}
	}
}
