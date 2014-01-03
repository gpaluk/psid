package psid 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class WavaData 
	{
		
		[Embed(source = "wavedata/WAVE6581__ST", mimeType = "application/octet-stream")]
		private static const CWAVE_6581__ST:Class;
		
		[Embed(source = "wavedata/WAVE6581_P_T", mimeType = "application/octet-stream")]
		private static const CWAVE_6581_P_T:Class;
		
		[Embed(source = "wavedata/WAVE6581_PS_", mimeType = "application/octet-stream")]
		private static const CWAVE_6581_PS_:Class;
		
		[Embed(source = "wavedata/WAVE6581_PST", mimeType = "application/octet-stream")]
		private static const CWAVE_6581_PST:Class;
		
		public static const WAVE_6581__ST:ByteArray = new CWAVE_6581__ST();
		public static const WAVE_6581_P_T:ByteArray = new CWAVE_6581_P_T();
		public static const WAVE_6581_PS_:ByteArray = new CWAVE_6581_PS_();
		public static const WAVE_6581_PST:ByteArray = new CWAVE_6581_PST();
		
		
		
		
		
		[Embed(source = "wavedata/WAVE8580__ST", mimeType = "application/octet-stream")]
		private static const CWAVE_8580__ST:Class;
		
		[Embed(source = "wavedata/WAVE8580_P_T", mimeType = "application/octet-stream")]
		private static const CWAVE_8580_P_T:Class;
		
		[Embed(source = "wavedata/WAVE8580_PS_", mimeType = "application/octet-stream")]
		private static const CWAVE_8580_PS_:Class;
		
		[Embed(source = "wavedata/WAVE8580_PST", mimeType = "application/octet-stream")]
		private static const CWAVE_8580_PST:Class;
		
		public static const WAVE_8580__ST:ByteArray = new CWAVE_8580__ST();
		public static const WAVE_8580_P_T:ByteArray = new CWAVE_8580_P_T();
		public static const WAVE_8580_PS_:ByteArray = new CWAVE_8580_PS_();
		public static const WAVE_8580_PST:ByteArray = new CWAVE_8580_PST();
		
		public function WavaData() 
		{
			throw new Error( "Cannot instantiate a static class." );
		}
		
	}

}