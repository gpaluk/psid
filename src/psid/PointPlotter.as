package psid 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class PointPlotter 
	{
		
		protected var _sample:ByteArray;
		
		public function PointPlotter(arr:ByteArray) 
		{
			_sample = arr;
		}
		
		public function plot(x:Number, y:Number):void
		{
			if (y < 0)
			{
				y = 0;
			}
			
			_sample[int( x )] = int( y );
		}
	}

}