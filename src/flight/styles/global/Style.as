/**
 *
 */
package flight.styles.global
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	import flash.utils.getQualifiedClassName;

	import flight.data.DataChange;
	import flight.display.RenderPhase;
	import flight.events.StyleEvent;
	
	/**
	 * A style object on which dynamic style data is stored.
	 */
	dynamic public class Style extends NoisyObject
	{
		private var _target:DisplayObject;
		
		public function Style(target:DisplayObject)
		{
			register(onUpdate);
			_target = target;
			var className:String = getQualifiedClassName(target).split("::").pop();
			super(Styles.getTypeStyles(className));
		}

		/**
		 * This is called whenever a style is changed for global (*), the target's type (e.g. Button), or set directly
		 * on this style object.
		 */
		private function onUpdate(property:String, oldValue:*, newValue:*):void
		{
			RenderPhase.invalidate(_target, StylePhase.STYLE);
			DataChange.change(this, property, oldValue, newValue);
		}
	}
}
