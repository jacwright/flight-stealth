/**
 *
 */
package flight.styles.hierarchical
{
	import flash.display.DisplayObject;

	import flash.events.Event;

	import flight.styles.IStyleable;
	import flight.utils.BrazenObject;

	dynamic public class Style extends BrazenObject
	{
		protected var target:IStyleable;
		protected var display:DisplayObject;
		
		public function Style(target:IStyleable)
		{
			super(new BrazenObject()); // allow the setting of stylesheet styles to trigger updates
			
			this.target = target;
			display = target as DisplayObject;
			
			if (!display) {
				throw new ArgumentError("Style target must be an IStyleable display object.");
			}
			
			display.addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			if (display.stage) {
				updateStyles();
			}
		}
		
		protected function updateStyles():void
		{
			
		}
		
		private function onAdded(event:Event):void
		{
			retrieveStyles();
		}
	}
}
