/*
 * Copyright (c) 2010 the original author or authors.
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package flight.metadata
{
	import flight.data.DataBind;
	
	/**
	 * @experimental
	 */
	public function resolveBindings(instance:Object):void
	{
		var desc:XMLList = Type.describeProperties(instance, "Binding");
		for each (var prop:XML in desc) {
			var meta:XMLList = prop.metadata.(@name == "Binding");
			
			// to support multiple Binding metadata tags on a single property
			for each (var tag:XML in meta) {
				var targ:String = ( tag.arg.(@key == "target").length() > 0 ) ?
					tag.arg.(@key == "target").@value :
					tag.arg.@value;
				
				DataBind.bind(instance, targ, instance, prop.@name, true);
			}
		}
	}
	
}
