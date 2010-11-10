/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.display
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import flight.data.DataChange;
	import flight.layouts.Bounds;
	import flight.layouts.Box;
	import flight.layouts.IBounds;
	import flight.layouts.ILayoutBounds;
	import flight.styles.IStyleable;
	import flight.styles.Style;
	
	import mx.core.IMXMLObject;
	
	[Style(name="left")]
	[Style(name="top")]
	[Style(name="right")]
	[Style(name="bottom")]
	[Style(name="horizontal")]
	[Style(name="vertical")]
	[Style(name="offsetX")]
	[Style(name="offsetY")]
	[Style(name="dock")]
	[Style(name="tile")]
	
	[Event(name="initialize", type="flash.events.Event")]
	[Event(name="style", type="flash.events.Event")]
	[Event(name="move", type="flash.events.Event")]
	[Event(name="resize", type="flash.events.Event")]
	[Event(name="ready", type="flash.events.Event")]
	
	/**
	 * Advanced Shape implementation providing styling, transformation and
	 * simple layout properties, also making the display bindable.
	 */
	public class ShapeDisplay extends Shape implements IStyleable, ITransform, ILayoutBounds, IInvalidating, IMXMLObject
	{
		public function ShapeDisplay()
		{
			_explicit = new Bounds(NaN, NaN);
			_measured = new Bounds(0, 0);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(LayoutPhase.MEASURE, onMeasure);
		}
		
		// ====== IStyleable implementation ====== //
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="idChange", style="noEvent")]
		public function get id():String { return _id; }
		public function set id(value:String):void
		{
			DataChange.change(this, "id", _id, _id = value);
		}
		private var _id:String;
		
		/**
		 * @inheritDoc
		 */
		override public function set name(value:String):void
		{
			id = super.name = value;
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="styleNameChange", style="noEvent")]
		public function get styleName():String { return _styleName;}
		public function set styleName(value:String):void
		{
			DataChange.change(this, "styleName", _styleName, _styleName = value);
		}
		private var _styleName:String;
		
		/**
		 * @inheritDoc
		 */
		public function get style():Object { return _style ||= new Style(this); }
		private var _style:Style;
		
		/**
		 * @inheritDoc
		 */
		public function getStyle(property:String):*
		{
			return style[property];
		}
		
		/**
		 * @inheritDoc
		 */
		public function setStyle(property:String, value:*):void
		{
			style[property] = value;
		}
		
		
		// ====== ITransform implementation ====== //
		
//		/**
//		 * @inheritDoc
//		 */
//		[Bindable(event="parentTransformChange", style="noEvent")]	// TODO: implement support from layout for non-children
//		public function get parentTransform():ITransform { return _parentTransform; }
//		public function set parentTransform(value:ITransform):void
//		{
//			DataChange.change(this, "parentTransform", _parentTransform, _parentTransform = value);
//		}
//		private var _parentTransform:ITransform;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="xChange", style="noEvent")]
		override public function set x(value:Number):void
		{
			if (_snapToPixel) {
				value = Math.round(value);
			}
			if (super.x != value) {
				// TODO: update registration point if transformX/Y != 0
				invalidateLayout();
				RenderPhase.invalidate(this, LayoutPhase.MOVE);
				DataChange.change(this, "x", super.x, super.x = value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="yChange", style="noEvent")]
		override public function set y(value:Number):void
		{
			if (_snapToPixel) {
				value = Math.round(value);
			}
			if (super.y != value) {
				// TODO: update registration point if transformX/Y != 0
				invalidateLayout();
				RenderPhase.invalidate(this, LayoutPhase.MOVE);
				DataChange.change(this, "y", super.y, super.y = value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="widthChange", style="noEvent")]
		override public function get width():Number { return _width; }
		override public function set width(value:Number):void
		{
			if (parent is ILayoutBounds) {
				var parentBounds:ILayoutBounds = ILayoutBounds(parent);
				var max:Number = parentBounds.maxWidth - (parentBounds.minWidth - _width);
				if (value > max) {
					value = max < 0 ? 0 : max;
				}
			}
			_explicit.width = value;
			updateWidth();
		}
		private var _width:Number = 0;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="heightChange", style="noEvent")]
		override public function get height():Number { return _height; }
		override public function set height(value:Number):void
		{
			if (parent is ILayoutBounds) {
				var parentBounds:ILayoutBounds = ILayoutBounds(parent);
				var max:Number = parentBounds.maxHeight - (parentBounds.minHeight - _height);
				if (value > max) {
					value = max < 0 ? 0 : max;
				}
			}
			_explicit.height = value;
			updateHeight();
		}
		private var _height:Number = 0;
		
		/**
		 * The width of the display in pixels relative to the local
		 * coordinates of the parent. The nativeWidth is calculated based on
		 * the bounds of the content of this display instance. When setting
		 * the nativeWidth property the scaleX property is adjusted
		 * accordingly.
		 */
		[Bindable(event="nativeWidthChange", style="noEvent")]
		public function get nativeWidth():Number { return super.width; }
		
		/**
		 * The height of the display in pixels relative to the local
		 * coordinates of the parent. The nativeHeight is calculated based on
		 * the bounds of the content of this display instance. When setting
		 * the nativeHeight property the scaleY property is adjusted
		 * accordingly.
		 */
		[Bindable(event="nativeHeightChange", style="noEvent")]
		public function get nativeHeight():Number { return super.height; }
		
		[Inspectable(category="General")]
		[Bindable(event="nativeSizingChange", style="noEvent")]
		public function get nativeSizing():Boolean { return _nativeSizing }
		public function set nativeSizing(value:Boolean):void
		{
			unscaledRect = getRect(this);
			DataChange.change(this, "nativeSizing", _nativeSizing, _nativeSizing = value);
			updateWidth();
			updateHeight();
		}
		private var _nativeSizing:Boolean;
		private var unscaledRect:Rectangle;
		
		[Inspectable(category="General", defaultValue=true)]
		[Bindable(event="snapToPixelChange", style="noEvent")]
		public function get snapToPixel():Boolean { return _snapToPixel; }
		public function set snapToPixel(value:Boolean):void
		{
			if (_snapToPixel != value) {
				DataChange.change(this, "snapToPixel", _snapToPixel, _snapToPixel = value);
				if (_snapToPixel) {
					x = super.x;
					y = super.y;
					updateWidth();
					updateHeight();
				}
			}
		}
		private var _snapToPixel:Boolean = true;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="transformXChange", style="noEvent")]
		public function get transformX():Number { return _transformX; }
		public function set transformX(value:Number):void
		{
			// TODO: implement
			DataChange.change(this, "transformX", _transformX, _transformX = value);
		}
		private var _transformX:Number = 0;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="transformYChange", style="noEvent")]
		public function get transformY():Number { return _transformY; }
		public function set transformY(value:Number):void
		{
			// TODO: implement
			DataChange.change(this, "transformY", _transformY, _transformY = value);
		}
		private var _transformY:Number = 0;
		
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=1)]
		[Bindable(event="scaleXChange", style="noEvent")]
		override public function set scaleX(value:Number):void
		{
			if (super.scaleX != value) {
				// TODO: udpate position based on registration point if transformX/Y != 0
				invalidateLayout();
				DataChange.change(this, "scaleX", super.scaleX, super.scaleX = value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=1)]
		[Bindable(event="scaleYChange", style="noEvent")]
		override public function set scaleY(value:Number):void
		{
			if (super.scaleY != value) {
				// TODO: udpate position based on registration point if transformX/Y != 0
				invalidateLayout();
				DataChange.change(this, "scaleY", super.scaleY, super.scaleY = value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="rotationChange", style="noEvent")]
		override public function set rotation(value:Number):void
		{
			if (super.rotation != value) {
				// TODO: udpate position based on registration point if transformX/Y != 0
				invalidateLayout();
				DataChange.change(this, "rotation", super.rotation, super.rotation = value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		[Bindable(event="matrixChange", style="noEvent")]
		public function get matrix():Matrix
		{
			return _matrix || transform.matrix;
		}
		public function set matrix(value:Matrix):void
		{
//			if (_parentTransform == parent) {
				transform.matrix = value;
//			} else { // TODO: implement
//				_matrix = value;
//			}
		}
		private var _matrix:Matrix;
		
		/**
		 * @inheritDoc
		 */
		public function get display():DisplayObject { return this; }
		
		// ====== ILayoutBounds implementation ====== //
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="Change", style="noEvent")]
		public function get freeform():Boolean { return _freeform; }
		public function set freeform(value:Boolean):void
		{
			if (_freeform != value) {
				if (!isNaN(_layoutWidth)) {
					_layoutWidth = NaN;
					updateWidth();
				}
				if (!isNaN(_layoutWidth)) {
					_layoutHeight = NaN;
					updateHeight();
				}
				DataChange.change(this, "freeform", _freeform, _freeform = value);
			}
		}
		private var _freeform:Boolean = false;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=NaN)]
		[Bindable(event="percentWidthChange", style="noEvent")]
		public function get percentWidth():Number { return _percentWidth }
		public function set percentWidth(value:Number):void
		{
			if (value > 1) {
				value *= 0.01;
			}
			if (_percentWidth != value) {
				invalidateLayout();
				DataChange.change(this, "percentWidth", _percentWidth, _percentWidth = value);
			}
		}
		private var _percentWidth:Number = NaN;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=NaN)]
		[Bindable(event="percentHeightChange", style="noEvent")]
		public function get percentHeight():Number { return _percentHeight }
		public function set percentHeight(value:Number):void
		{
			if (value > 1) {
				value *= 0.01;
			}
			if (_percentHeight != value) {
				invalidateLayout();
				DataChange.change(this, "percentHeight", _percentHeight, _percentHeight = value);
			}
		}
		private var _percentHeight:Number = NaN;
		
		/**
		 * @inheritDoc
		 */
		public function get preferredWidth():Number
		{
			return !isNaN(_explicit.width) ? _explicit.width : _measured.width;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get preferredHeight():Number
		{
			return !isNaN(_explicit.height) ? _explicit.height : _measured.height;
		}
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", type="String")]
		[Bindable(event="marginChange", style="noEvent")]
		public function get margin():Box { return _margin ||= new Box(); }
		public function set margin(value:*):void
		{
			if (value is String) {
				value = Box.fromString(value);
			} else if (value is Number) {
				value = new Box(value, value, value, value);
			} else {
				value = value as Box;
			}
			
			if (_margin) {
				_margin.removeEventListener(Event.CHANGE, onMarginChange);
			}
			DataChange.queue(this, "margin", _margin, _margin = value);
			if (_margin) {
				_margin.addEventListener(Event.CHANGE, onMarginChange);
			}
			
			invalidateLayout();
			DataChange.change();
		}
		private var _margin:Box;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="minWidthChange", style="noEvent")]
		public function get minWidth():Number { return _minWidth;}
		public function set minWidth(value:Number):void
		{
			if (value > _explicit.maxWidth) {
				value = _explicit.maxWidth;
			}
			_explicit.minWidth = value;
			value = _measured.constrainWidth(value);
			if (value > _explicit.maxWidth) {
				value = _explicit.maxWidth;
			}
			if (_minWidth != value) {
				invalidateLayout(true);
				DataChange.queue(this, "minWidth", _minWidth, _minWidth = value);
				updateWidth();
				DataChange.change();
			}
		}
		private var _minWidth:Number = 0;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General")]
		[Bindable(event="minHeightChange", style="noEvent")]
		public function get minHeight():Number { return _minHeight;}
		public function set minHeight(value:Number):void
		{
			if (value > _explicit.maxHeight) {
				value = _explicit.maxHeight;
			}
			_explicit.minHeight = value;
			value = _measured.constrainHeight(value);
			if (value > _explicit.maxHeight) {
				value = _explicit.maxHeight;
			}
			if (_minHeight != value) {
				invalidateLayout(true);
				DataChange.queue(this, "minHeight", _minHeight, _minHeight = value);
				updateHeight();
				DataChange.change();
			}
		}
		private var _minHeight:Number = 0;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=0xFFFFFF)]
		[Bindable(event="maxWidthChange", style="noEvent")]
		public function get maxWidth():Number { return _maxWidth;}
		public function set maxWidth(value:Number):void
		{
			if (_explicit.minWidth > value) {
				_explicit.minWidth = value;
			}
			_explicit.maxWidth = value;
			if (value > _measured.maxWidth) {
				value = _measured.maxWidth;
			}
			if (_maxWidth != value) {
				invalidateLayout(true);
				DataChange.queue(this, "maxWidth", _maxWidth, _maxWidth = value);
				updateWidth();
				DataChange.change();
			}
		}
		private var _maxWidth:Number = 0xFFFFFF;
		
		/**
		 * @inheritDoc
		 */
		[Inspectable(category="General", defaultValue=0xFFFFFF)]
		[Bindable(event="maxHeightChange", style="noEvent")]
		public function get maxHeight():Number { return _maxHeight;}
		public function set maxHeight(value:Number):void
		{
			if (_explicit.minHeight > value) {
				_explicit.minHeight = value;
			}
			_explicit.maxHeight = value;
			if (value > _measured.maxHeight) {
				value = _measured.maxHeight;
			}
			if (_maxHeight != value) {
				invalidateLayout(true);
				DataChange.queue(this, "maxHeight", _maxHeight, _maxHeight = value);
				updateHeight();
				DataChange.change();
			}
		}
		private var _maxHeight:Number = 0xFFFFFF;
		
		/**
		 * @inheritDoc
		 */
		public function get explicit():IBounds { return _explicit; }
		private var _explicit:IBounds;
		
		/**
		 * @inheritDoc
		 */
		public function get measured():IBounds { return _measured; }
		private var _measured:IBounds;
		
		/**
		 * @inheritDoc
		 */
		public function setLayoutPosition(x:Number, y:Number):void
		{
			if (complexMatrix()) {
				var m:Matrix = matrix, d:Number;
				if (_nativeSizing) {
					m = resetMatrixScale(m);
				}
				d = m.a * _width + m.c * _height;
				if (d < 0) x -= d;
				d = m.d * _height + m.b * _width;
				if (d < 0) y -= d;
			}
			
			if (_snapToPixel) {
				x = Math.round(x);
				y = Math.round(y);
			}
			RenderPhase.invalidate(this, LayoutPhase.MOVE);
			DataChange.queue(this, "x", super.x, super.x = x);
			DataChange.change(this, "y", super.y, super.y = y);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setLayoutSize(width:Number, height:Number):void
		{
			if (complexMatrix()) {
				var m:Matrix = matrix;
				if (_nativeSizing) {
					m = resetMatrixScale(m);
				}
				m.invert();
				
				if (width < 0) {
					width = 0;
				}
				if (height < 0) {
					height = 0;
				}
				_layoutWidth = Math.abs(m.a * width + m.c * height);
				_layoutHeight = Math.abs(m.d * height + m.b * width);
			} else if (_nativeSizing) {
				_layoutWidth = width;
				_layoutHeight = height;
			} else {
				_layoutWidth = width / scaleX;
				_layoutHeight = height / scaleY;
			}
			
			if (_layoutWidth == preferredWidth) {
				_layoutWidth = NaN;
			}
			if (_layoutHeight == preferredHeight) {
				_layoutHeight = NaN;
			}
			updateWidth(true);
			updateHeight(true);
		}
		private var _layoutWidth:Number;
		private var _layoutHeight:Number;
		
		/**
		 * @inheritDoc
		 */
		public function getLayoutRect(width:Number = NaN, height:Number = NaN):Rectangle
		{
			if (isNaN(width)) width = _width;
			if (isNaN(height)) height = _height;
			
			if (complexMatrix()) {
				var m:Matrix = matrix;
				if (_nativeSizing) {
					m = resetMatrixScale(m);
				}
				var x:Number, y:Number;
				var minX:Number, minY:Number, maxX:Number, maxY:Number;
				
				minX = maxX = m.tx;
				minY = maxY = m.ty;
				
				x = m.a * width + m.tx;
				y = m.b * width + m.ty;
				if (x < minX) {
					minX = x;
				} else if (x > maxX) {
					maxX = x;
				}
				if (y < minY) {
					minY = y;
				} else if (y > maxY) {
					maxY = y;
				}
				
				x = m.a * width + m.c * height + m.tx;
				y = m.d * height + m.b * width + m.ty;
				if (x < minX) {
					minX = x;
				} else if (x > maxX) {
					maxX = x;
				}
				if (y < minY) {
					minY = y;
				} else if (y > maxY) {
					maxY = y;
				}
				
				x = m.c * width + m.tx;
				y = m.d * width + m.ty;
				if (x < minX) {
					minX = x;
				} else if (x > maxX) {
					maxX = x;
				}
				if (y < minY) {
					minY = y;
				} else if (y > maxY) {
					maxY = y;
				}
				
				rect.x = minX;
				rect.y = minY;
				rect.width = maxX - minX;
				rect.height = maxY - minY;
			} else {
				rect.x = this.x;
				rect.y = this.y;
				if (_nativeSizing) {
					rect.width = width;
					rect.height = height;
				} else {
					rect.width = width * scaleX;
					rect.height = height * scaleY;
				}
			}
			return rect;
		}
		private var rect:Rectangle = new Rectangle();
		
		/**
		 * @inheritDoc
		 */
		public function constrainWidth(width:Number):Number
		{
			return (width >= _maxWidth) ? _maxWidth :
				   (width <= _minWidth) ? _minWidth : width;
		}
		
		/**
		 * @inheritDoc
		 */
		public function constrainHeight(height:Number):Number
		{
			return (height >= _maxHeight) ? _maxHeight :
				   (height <= _minHeight) ? _minHeight : height;
		}
		
		/**
		 * @inheritDoc
		 */
		public function invalidate(phase:String = null):void
		{
			RenderPhase.invalidate(this, phase || RenderPhase.VALIDATE);
		}
		
		/**
		 * @inheritDoc
		 */
		public function validateNow(phase:String = null):void
		{
			RenderPhase.validateNow(this, phase);
		}
		
		/**
		 * Specialized method for MXML, called after the display has been
		 * created and all of its properties specified in MXML have been
		 * initialized.
		 * 
		 * @param		document	The MXML document defining this display.
		 * @param		id			The identifier used by <code>document</code>
		 * 							to refer to this display, or its instance
		 * 							name.
		 */
		public function initialized(document:Object, id:String):void
		{
			this.id = super.name = id;
		}
		
		protected function measure():void
		{
			var rect:Rectangle = getRect(this);
			_measured.width = rect.width;
			_measured.height = rect.height;
		}
		
		protected function invalidateLayout(measureOnly:Boolean = false):void
		{
			if (!_freeform) {
				RenderPhase.invalidate(parent, LayoutPhase.MEASURE);
				if (!measureOnly) {
					RenderPhase.invalidate(parent, LayoutPhase.LAYOUT);
				}
			}
		}
		
		private function updateWidth(layout:Boolean = false):void
		{
			var w:Number = !isNaN(_layoutWidth) ? _layoutWidth : preferredWidth;
			w = constrainWidth(w);
			if (_snapToPixel) {
				w = Math.round(w);
			}
			if (_width != w) {
				if (!layout) {
					invalidateLayout();
				}
				RenderPhase.invalidate(this, LayoutPhase.LAYOUT);
				RenderPhase.invalidate(this, LayoutPhase.RESIZE);
				if (_nativeSizing) {
					DataChange.queue(this, "scaleX", super.scaleX, super.scaleX = w / unscaledRect.width);
				}
				DataChange.change(this, "width", _width, _width = w);
			}
		}
		
		private function updateHeight(layout:Boolean = false):void
		{
			var h:Number = !isNaN(_layoutHeight) ? _layoutHeight : preferredHeight;
			h = constrainHeight(h);
			if (_snapToPixel) {
				h = Math.round(h);
			}
			if (_height != h) {
				if (!layout) {
					invalidateLayout();
				}
				RenderPhase.invalidate(this, LayoutPhase.LAYOUT);
				RenderPhase.invalidate(this, LayoutPhase.RESIZE);
				if (_nativeSizing) {
					DataChange.change(this, "scaleY", super.scaleY, super.scaleY = h / unscaledRect.height);
				}
				DataChange.change(this, "height", _height, _height = h);
			}
		}
		
		private function complexMatrix():Boolean
		{
			var m:Matrix = matrix;
			return (m.a < 0 || m.d < 0 ||
					m.b != 0 || m.c != 0);
		}
		
		private function resetMatrixScale(m:Matrix):Matrix
		{
			// set scale back to 1 but keep rotation
			var skewY:Number = Math.atan2(m.b, m.a);
			m.a = Math.cos(skewY);
			m.b = Math.sin(skewY);
			var skewX:Number = Math.atan2(-m.c, m.d);
			m.c = -Math.sin(skewX);
			m.d = Math.cos(skewX);
			return m;
		}
		
		private function onMeasure(event:Event):void
		{
			measure();
			minWidth = _explicit.minWidth;
			minHeight = _explicit.minHeight;
			maxWidth = _explicit.maxWidth;
			maxHeight = _explicit.maxHeight;
			updateWidth();
			updateHeight();
		}
		
		private function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			RenderPhase.invalidate(this, InitializePhase.INITIALIZE);
			RenderPhase.invalidate(this, InitializePhase.READY);
			RenderPhase.invalidate(this, LayoutPhase.MEASURE);
		}
		
		private function onMarginChange(event:Event):void
		{
			invalidateLayout();
		}
	}
}
