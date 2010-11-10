/**
 *
 */
package flight.styles.global
{
	import flash.utils.Proxy;

	/**
	 * A noisy object lets registered functions know whenever any of its properties have changed. It can also wrap an
	 * object and will contain all properties of the wrapped object plus ones explicitly set on this. Values cannot be
	 * set on a wrapped object from this noisy object, only retrieved. And values can only be retrieved from the wrapped
	 * object when they are not set on this object explicitly.
	 * 
	 * Note that behavior when wrapping an object is not always what one might expect. For example, if "foo" is set to
	 * 5 on this object and 10 on the wrapped object, when it is deleted from this object (delete obj.foo) instead of
	 * becoming undefined it becomes 10 (i.e. goes from 5 to 10). 
	 */
	dynamic public class NoisyObject extends Proxy
	{
		private var listeners:Array = [];
		private var data:Object = {};
		private var wrap:Object;
		private var names:Array;
		
		public function NoisyObject(wrap:Object = null)
		{
			if (wrap) {
				this.wrap = wrap;
				if (wrap is NoisyObject) {
					NoisyObject(wrap).register(onUpdate);
				}
			}
		}
		
		/**
		 * Register a function as a listener to know when this object has changed properties. If this object wraps
		 * another then it will be sure to update listeners about changes inside that are visible here.
		 * @param listener The listening function with a method signature of:
		 * (obj:Object, property:String, oldValue:*, newValue:*)
		 * (property:String, oldValue:*, newValue:*)
		 * (property:String, newValue:*)
		 * (newValue:*)
		 * ()
		 * any of these will work.
		 */
		public function register(listener:Function):void
		{
			unregister(listener);
			listeners.push(listener);
		}
		
		/**
		 * Unregister a registered listener.
		 * @param listener A function which was registered.
		 */
		public function unregister(listener:Function):void
		{
			var index = listeners.indexOf(listener);
			if (index != -1)
				listeners.splice(index, 1);
		}
		
		// GET SET AND DELETE THIS OBJECT'S PROPERTIES
		
		override flash_proxy function getProperty(name:*):*
		{
			var prop:String = name.localName;
			return prop in data ? data[prop] : (wrap && prop in wrap ? wrap[prop] : undefined);
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			var prop:String = name.localName;
			if (data[prop] != value) {
				var oldValue:* = this[name];
				data[prop] = value;
				// we may have set the prop explicitly without it changing, check if it actually changed
				if (oldValue != value) {
					update(prop, oldValue, value);
				}
			}
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			var prop:String = name.localName;
			return prop in data || (wrap && prop in wrap);
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			var oldValue:* = this[name], value:*;
			var deleted:Boolean = delete data[name];
			if (deleted && oldValue != (value = this[name]) ) {
				update(name, oldValue, value);
			}
			return deleted;
		}
		
		// ITERATE OVER THE OBJECT'S PROPERTIES
		
		override flash_proxy function nextName(index:int):String
		{
			return String(names[index - 1]);
		}
		
		override flash_proxy function nextValue(index:int):*
		{
			var prop:String = names[index - 1];
			return this[prop];
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			if (index == 0) {
				// initialize names
				var names:Array = [];
				for (var i:String in data) {
					names.push(i);
				}
				if (wrap) {
					for (var j:String in wrap) {
						if ( !(j in data) ) names.push(j);
					}
				}
				this.names = names;
			}
			return (index + 1) % (names.length + 1);
		}

		/**
		 * Let any listening method's know that this property's value has changed.
		 * @param property
		 * @param oldValue
		 * @param value
		 */
		private function update(property:String, oldValue:*, value:*):void
		{
			for (var i:int = 0, l:int = listeners.length; i < l; i++) {
				var listener:Function = listeners[i];
				switch (listener.length) {
					case 4: listener(obj, property, oldValue, value); break;
					case 3: listener(property, oldValue, value); break;
					case 2: listener(property, value); break;
					case 1: listener(value); break;
					case 0: listener(); break;
				}
			}
		}

		/**
		 * When this object wraps another NoisyObject and the wrapped object's property changes be sure to let those
		 * listening know that the property has changed if it has affected this object.
		 * @param property
		 * @param oldValue
		 * @param value
		 */
		private function onUpdate(property:String, oldValue:*, value:*):void
		{
			if ( !(property in data) && oldValue != value) {
				update(property, oldValue, value);
			}
		}
	}
}
