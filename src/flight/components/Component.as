/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.components
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import flight.behaviors.CompositeBehavior;
	import flight.behaviors.IBehavior;
	import flight.behaviors.IBehavioral;
	import flight.data.DataBind;
	import flight.data.DataChange;
	import flight.display.SpriteDisplay;
	import flight.display.RenderPhase;
	import flight.measurement.resolveHeight;
	import flight.measurement.resolveWidth;
	import flight.metadata.resolveCommitProperties;
	import flight.skins.ISkin;
	import flight.skins.ISkinnable;
	import flight.templating.addItem;
	
	import mx.core.IDataRenderer;
	
	[Style(name="left")]
	[Style(name="right")]
	[Style(name="top")]
	[Style(name="bottom")]
	[Style(name="horizontalCenter")]
	[Style(name="verticalCenter")]
	[Style(name="dock")]
	[Style(name="align")]
	
	/**
	 * @alpha
	 */
	public class Component extends SpriteDisplay implements IBehavioral, ISkinnable, IDataRenderer
	{
		
		static public const MEASURE:String = "measure";
		RenderPhase.registerPhase(MEASURE, 0, true);
		
		protected var dataBind:DataBind = new DataBind();
		
		private var _data:Object;
		
		private var _skin:Object;
		private var _behaviors:CompositeBehavior;
		
		private var _states:Array;
		private var _currentState:String;
		
		private var _enabled:Boolean = true;
		
		public function Component()
		{
			_behaviors = new CompositeBehavior(this);
			resolveCommitProperties(this);
			addEventListener(MEASURE, onMeasure, false, 0, true);
		}
		
		[Bindable(event="dataChange")]
		public function get data():Object { return _data; }
		public function set data(value:Object):void
		{
			if (_data == value) {
				return;
			}
			_data = value;
			dispatchEvent(new Event("dataChange"));
		}
		
		
		[ArrayElementType("flight.behaviors.IBehavior")]
		[Bindable(event="behaviorsChange")]
		[Inspectable(name="Behaviors", type=Array)]
		/**
		 * A dynamic object or hash map of behavior objects. <code>behaviors</code>
		 * is effectively read-only, but setting either an IBehavior or array of
		 * IBehavior to this property will add those behaviors to the <code>behaviors</code>
		 * object/map.
		 * 
		 * To set behaviors in MXML:
		 * &lt;Component...&gt;
		 *   &lt;behaviors&gt;
		 *     &lt;SelectBehavior/&gt;
		 *     &lt;ButtonBehavior/&gt;
		 *   &lt;/behaviors&gt;
		 * &lt;/Component&gt;
		 */
		public function get behaviors():CompositeBehavior { return _behaviors; }
		public function set behaviors(value:*):void
		{
			/*
			var change:PropertyChange = PropertyChange.begin();
			value = change.add(this, "behaviors", _behaviors, value);
			*/
			_behaviors.clear();
			if (value is Array) {
				_behaviors.add(value);
			} else if (value is IBehavior) {
				_behaviors.add([value]);
			}
			//change.commit();
			dispatchEvent(new Event("behaviorsChange"));
		}
		
		[Bindable(event="skinChange")]
		[Inspectable(name="Skin", type=Class)]
		public function get skin():Object { return _skin; }
		public function set skin(value:Object):void
		{
			if (_skin == value) {
				return;
			}
			var oldSkin:Object = _skin;
			_skin = value;
			if (_skin is ISkin) {
				(_skin as ISkin).target = this;
			} else if (_skin is DisplayObject) {
				addItem(this, _skin);
			}
			flight.measurement.setSize(skin, width, height);
			dispatchEvent(new Event("skinChange"));
			RenderPhase.invalidate(this, MEASURE);
		}
		
		[Bindable(event="enabledChange")]
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void
		{
			DataChange.change(this, "enabled", _enabled, _enabled = value);
		}
		
		// IStateful implementation
		/*
		[Bindable(event="statesChange")]
		public function get states():Array { return _states; }
		public function set states(value:Array):void {
			if (_states == value) {
				return;
			}
			PropertyEvent.dispatchChange(this, "states", _states, _states = value);
		}
		*/
		
		[Bindable(event="currentStateChange", style="weak")]
		public function get currentState():String { return _currentState; }
		public function set currentState(value:String):void
		{
			DataChange.change(this, "currentState", _currentState, _currentState = value);
			if (_skin && "currentState" in _skin) {
				_skin.currentState = _currentState;
			}
		}
		
		// needs more thought
		
		override public function set width(value:Number):void
		{
			super.width = value;
			flight.measurement.setSize(skin, value, height);
		}
		
		override public function set height(value:Number):void
		{
			super.height = value;
			flight.measurement.setSize(skin, width, value);
		}
		
		override public function setLayoutSize(width:Number, height:Number):void
		{
			super.setLayoutSize(width, height);
			flight.measurement.setSize(skin, width, height);
		}
		
		private function onMeasure(event:Event):void
		{
			if ((isNaN(explicit.width) || isNaN(explicit.height)) && skin) {
				measuredLayout.width = resolveWidth(skin); // explicit width of skin becomes measured width of component
				measuredLayout.height = resolveHeight(skin); // explicit height of skin becomes measured height of component
			}
		}
		
	}
}
