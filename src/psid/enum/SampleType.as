package psid.enum 
{
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class SampleType 
	{
		
		public static const FAST:SampleType = new SampleType( "fast" );
		public static const INTERPOLATE:SampleType = new SampleType( "interpolate" );
		public static const RESAMPLE_FAST:SampleType = new SampleType( "resampleFast" );
		public static const RESAMPLE_INTERPOLATE:SampleType = new SampleType( "resampleInterpolate" );
		
		private var _type:String;
		public function SampleType( type:String ) 
		{
			_type = type;
		}
		
		public function get type():String 
		{
			return _type;
		}
		
	}

}