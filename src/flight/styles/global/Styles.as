/**
 *
 */
package flight.styles.global
{
	import flight.utils.BrazenObject;

	/**
	 * Style management class for a global styling system. Set styles for all <code>IStyleable</code> objects of a
	 * certain class type (the type is the name of the class without the package). Use * to set a style for all objects
	 * of any type.
	 */
	public class Styles
	{
		static protected var allStyles:Object = {
			"*": new BrazenObject() // global styles
		};
		
		static public function getStyle(type:String, property:String):*
		{
			var typeStyles:Object = getTypeStyles(type);
			return typeStyles[property];
		}
		
		static public function setStyle(type:String, property:String, value:*):void
		{
			var typeStyles:Object = getTypeStyles(type);
			typeStyles[property] = value;
		}
		
		static public function getTypeStyles(type:String):Object
		{
			return allStyles[type] ||= new BrazenObject(allStyles["*"]);
		}
	}
}
