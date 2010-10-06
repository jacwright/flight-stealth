/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.layouts
{
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flight.measurement.resolveHeight;
	import flight.measurement.resolveWidth;
	
	[LayoutProperty(name="width", measure="true")]
	[LayoutProperty(name="height", measure="true")]
	
	/**
	 * Provides a measured layout from top to bottom.
	 * 
	 * @alpha
	 **/
	public class VerticalLayout extends Layout implements ILayout
	{
		
		
		public var gap:Number = 5;
		
		override public function measure(children:Array):Point
		{
			super.measure(children);
			var point:Point = new Point(0, gap / 2);
			for each(var child:Object in children) {
				var width:Number = resolveWidth(child);
				var height:Number = resolveHeight(child);
				point.x = Math.max(point.x, width);
				point.y += height + gap;
			}
			point.y -= gap / 2;
			return point;
		}
		
		override public function update(children:Array, rectangle:Rectangle):void
		{
			super.update(children, rectangle);
			if (children) {
				var position:Number = gap / 2;
				var length:int = children.length;
				for (var i:int = 0; i < length; i++) {
					var child:Object = children[i];
					var width:Number = resolveWidth(child);
					var height:Number = resolveHeight(child);
					child.x = rectangle.width / 2 - width / 2;
					child.y = position;
					position += height + gap;
				}
			}
		}
		
	}
}
