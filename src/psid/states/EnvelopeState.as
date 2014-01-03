package psid.states 
{
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class EnvelopeState
	{
		
		public static const ATTACK:EnvelopeState = new EnvelopeState( "attack" );
		public static const DECAY_SUSTAIN:EnvelopeState = new EnvelopeState( "decaySustain" );
		public static const RELEASE:EnvelopeState = new EnvelopeState( "release" );
		
		private var _type:String;
		public function EnvelopeState( type:String ) 
		{
			_type = type;
		}
		
		public function get type():String 
		{
			return _type;
		}
		
	}

}