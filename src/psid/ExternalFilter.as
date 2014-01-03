package psid 
{
	import psid.enum.SFXChipType;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class ExternalFilter 
	{
		private static const PI:Number = 3.1415926535897932385;
		
		protected var _enabled:Boolean;
		protected var _mixer_DC:int;
		protected var _vlp:int;
		protected var _vhp:int;
		protected var _vo:int;
		protected var _w0lp:int;
		protected var _w0hp:int;
		
		[Inline]
		public final function clock(Vi:int):void
		{
			if (!_enabled) {
				_vlp = _vhp = 0;
				_vo = Vi - _mixer_DC;
				return;
			}
			var dVlp:int = (_w0lp >> 8) * (Vi - _vlp) >> 12;
			var dVhp:int = _w0hp * (_vlp - _vhp) >> 20;
			_vo = _vlp - _vhp;
			_vlp += dVlp;
			_vhp += dVhp;
		}
		
		[Inline]
		public final function clockDelta(delta_t:int, Vi:int):void
		{
			if (!_enabled) {
				_vlp = _vhp = 0;
				_vo = Vi - _mixer_DC;
				return;
			}
			
			var delta_t_flt:int = 8;
			
			while (delta_t != 0) {
				if (delta_t < delta_t_flt) {
					delta_t_flt = delta_t;
				}
				
				var dVlp:int = (_w0lp * delta_t_flt >> 8) * (Vi - _vlp) >> 12;
				var dVhp:int = _w0hp * delta_t_flt * (_vlp - _vhp) >> 20;
				_vo = _vlp - _vhp;
				_vlp += dVlp;
				_vhp += dVhp;
				
				delta_t -= delta_t_flt;
			}
		}
		
		[Inline]
		public final function get output():int
		{
			return _vo;
		}
		
		public function ExternalFilter() 
		{
			reset();
			enable_filter(true);
			set_sampling_parameter(15915.6);
			set_chip_model(SFXChipType.MOS6581);
		}
		
		public function enable_filter(enable:Boolean):void
		{
			_enabled = enable;
		}
		
		public function set_sampling_parameter(pass_freq:Number):void
		{
			_w0hp = 105;
			_w0lp = (int /* sound_sample */) (pass_freq * (2.0 * PI * 1.048576));
			if (_w0lp > 104858)
				_w0lp = 104858;
		}
		
		public function set_chip_model(model:SFXChipType):void
		{
			if (model == SFXChipType.MOS6581)
			{
				_mixer_DC = ((((0x800 - 0x380) + 0x800) * 0xff * 3 - 0xfff * 0xff / 18) >> 7) * 0x0f;
			}
			else
			{
				_mixer_DC = 0;
			}
		}
		
		public function reset():void
		{
			_vlp = 0;
			_vhp = 0;
			_vo = 0;
		}
		
		
		
	}

}