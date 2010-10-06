package flight.layouts
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	
	import org.flexunit.Assert;
	
	import flight.display.SpriteDisplay;
	
	public class XYLayoutTest extends EventDispatcher
	{
		
		[Test]
		public function testMeasurement():void {
			var child1:SpriteDisplay = new SpriteDisplay();
			var child2:SpriteDisplay = new SpriteDisplay();
			
			child1.x = 5;
			child1.y = 5;
			child1.width = 20;
			child1.height = 20;
			
			child2.x = 10;
			child2.y = 10;
			child2.width = 20;
			child2.height = 20;
			
			var layout:XYLayout = new XYLayout();
			var point:Point = layout.measure([child1, child2]);
			Assert.assertEquals(30, point.x);
			Assert.assertEquals(30, point.y);
		}
		
	}
}
