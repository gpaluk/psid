package psid 
{
	import psid.enum.SFXChipType;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class Voice 
	{
		
		protected var _wave:WaveformGenerator = new WaveformGenerator();
		protected var _envelope:EnvelopeGenerator = new EnvelopeGenerator();
		
		protected var _muted:Boolean;
		
		protected var _wave_zero:int;
		protected var _voice_DC:int;
		
		public function get output():int
		{
			if (!_muted)
			{ 
				return ((_wave.output - _wave_zero) * _envelope.output + _voice_DC);
			}
			else
			{
				return 0;
			}
		}
		
		public function Voice() 
		{
			_muted = false;
			set_chip_model(SFXChipType.MOS6581);
		}
		
		public function set_chip_model(model:SFXChipType):void
		{
			_wave.set_chip_model(model);
			
			if (model == SFXChipType.MOS6581)
			{
				_wave_zero = 0x380;
				_voice_DC = 0x800 * 0xff;
			}
			else
			{
				_wave_zero = 0x800;
				_voice_DC = 0;
			}
		}
		
		public function set_sync_source(source:Voice):void
		{
			_wave.set_sync_source(source._wave);
		}
		
		public function writeCONTROL_REG(control:int):void
		{
			_wave.writeCONTROL_REG(control);
			_envelope.writeCONTROL_REG(control);
		}
		
		public function reset():void
		{
			_wave.reset();
			_envelope.reset();
		}
		
		public function mute(enable:Boolean):void
		{
			_muted = enable;
		}
	}
}