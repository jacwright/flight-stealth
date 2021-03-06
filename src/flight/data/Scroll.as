/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.data
{
	public class Scroll extends Range implements IScroll
	{
		[Bindable(event="pageSizeChange", style="noEvent")]
		public function get pageSize():Number { return _pageSize; }
		public function set pageSize(value:Number):void
		{
			DataChange.change(this, "pageSize", _pageSize, _pageSize = value);
		}
		private var _pageSize:Number = 10;
		
		public function Scroll(min:Number = 0, max:Number = 100)
		{
			super(min, max);
		}
		
		public function pageForward():Number
		{
			return value += _pageSize;
		}
		
		public function pageBackward():Number
		{
			return value -= _pageSize;
		}
		
	}
}
