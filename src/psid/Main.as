package psid
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import psid.EnvelopeGenerator;
	
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			var sid:SID = new SID();
		}
		
	}
	
}