package psid.enum 
{
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class SFXChipType 
	{
		public static const MOS6581:SFXChipType = new SFXChipType( "mos6581" );
		public static const MOS8580:SFXChipType = new SFXChipType( "mos8580" );
		
		private var _type:String;
		public function SFXChipType( type:String ) 
		{
			_type = type;
		}
		
		public function get type():String 
		{
			return _type;
		}
		
	}

}