/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.layouts
{
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import flight.data.DataBind;
	import flight.data.DataChange;
	import flight.display.RenderPhase;
	import flight.metadata.resolveBindings;
	import flight.metadata.resolveDataListeners;
	import flight.metadata.resolveEventListeners;
	import flight.metadata.resolveLayoutProperties;
	
	//[LayoutProperty(name="layout", measure="true")]
	//[LayoutProperty(name="measurements", measure="true")]
	/**
	 * The Layout class provides automated metadata handling for layouts which extend it.
	 * It is recommended that you extend this class to create custom layouts, but it's not required.
	 * 
	 * @alpha
	 **/
	public class Layout extends EventDispatcher implements ILayout
	{
		
		private var attached:Dictionary = new Dictionary(true);
		private var _target:IEventDispatcher;
		protected var dataBind:DataBind = new DataBind();
		
		[Bindable(event="targetChange")]
		public function get target():IEventDispatcher { return _target; }
		public function set target(value:IEventDispatcher):void
		{
			DataChange.change(this, "target", _target, _target = value);
		}
		
		public function Layout()
		{
			resolveBindings(this);
			resolveEventListeners(this);
			resolveDataListeners(this);
			dataBind.bindSetter(onInvalidateLayout, this, "target.width");
			dataBind.bindSetter(onInvalidateLayout, this, "target.height");
		}
		
		public function measure(children:Array):Point
		{
			// this method of listening for layout invalidating changes is very much experimental
			for each(var child:IEventDispatcher in children) {
				if (attached[child] != true) {
					resolveLayoutProperties(this, child, onInvalidateLayout);
					attached[child] = true;
				}
			}
			return new Point(0, 0);
		}
		
		public function update(children:Array, rectangle:Rectangle):void
		{
			// this method of listening for layout invalidating changes is very much experimental
			for each(var child:IEventDispatcher in children) {
				if (attached[child] != true) {
					resolveLayoutProperties(this, child, onInvalidateLayout);
					attached[child] = true;
				}
			}
		}
		
		private function onInvalidateLayout(object:*):void
		{
			if (target is DisplayObject) {
				RenderPhase.invalidate(target as DisplayObject, "measure");
				RenderPhase.invalidate(target as DisplayObject, "layout");
			}
		}
		
	}
}
