package psid 
{
	import flash.utils.ByteArray;
	import psid.enum.SFXChipType;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class WaveformGenerator 
	{
		
		protected var _sync_source:WaveformGenerator = null;
		protected var _sync_dest:WaveformGenerator = null;
		
		protected var _msb_rising:Boolean;
		protected var _accumulator:int;
		protected var _shift_register:int;
		protected var _freq:int;
		protected var _pw:int;
		protected var _waveform:int;
		protected var _test:int;
		protected var _ring_mod:int;
		protected var _sync:int;
		
		protected var _wave__ST:ByteArray;
		protected var _wave_P_T:ByteArray;
		protected var _wave_PS_:ByteArray;
		protected var _wave_PST:ByteArray;
		
		public function WaveformGenerator() 
		{
			_sync_source = this;
			set_chip_model(SFXChipType.MOS6581);
			reset();
		}
		
		public function set_sync_source(source:WaveformGenerator):void
		{
			_sync_source = source;
			source._sync_dest = this;
		}
		
		public function set_chip_model(chip_model:SFXChipType):void
		{
			if (chip_model == SFXChipType.MOS6581)
			{
				_wave__ST = WavaData.WAVE_6581__ST;
				_wave_P_T = WavaData.WAVE_6581_P_T;
				_wave_PS_ = WavaData.WAVE_6581_PS_;
				_wave_PST = WavaData.WAVE_6581_PST;
			}
			else
			{
				_wave__ST = WavaData.WAVE_8580__ST;
				_wave_P_T = WavaData.WAVE_8580_P_T;
				_wave_PS_ = WavaData.WAVE_8580_PS_;
				_wave_PST = WavaData.WAVE_8580_PST;
			}
		}
		
		public function writeFREQ_LO(freq_lo:int):void
		{
			_freq = _freq & 0xff00 | freq_lo & 0x00ff;
		}
		
		public function writeFREQ_HI(freq_hi:int):void
		{
			_freq = (freq_hi << 8) & 0xff00 | _freq & 0x00ff;
		}
		
		public function writePW_LO(pw_lo:int):void
		{
			_pw = _pw & 0xf00 | pw_lo & 0x0ff;
		}
		
		public function writePW_HI(pw_hi:int):void
		{
			_pw = (pw_hi << 8) & 0xf00 | _pw & 0x0ff;
		}
		
		public function writeCONTROL_REG(control:int):void
		{
			_waveform = (control >> 4) & 0x0f;
			_ring_mod = control & 0x04;
			_sync = control & 0x02;
			
			var test_next:int = control & 0x08;
			
			if (Config.ANTTI_LANKILA_PATCH)
			{
				if (test_next != 0 && _test == 0) {
					_accumulator = 0;
					var bit19:int = (_shift_register >> 19) & 1;
					_shift_register = (_shift_register & 0x7ffffd) | ((bit19 ^ 1) << 1);
				}
				else if (test_next == 0 && _test > 0)
				{
					var bit0:int = ((_shift_register >> 22) ^ (_shift_register >> 17)) & 0x1;
					_shift_register <<= 1;
					_shift_register &= 0x7fffff;
					_shift_register |= bit0;
				}
				if (_waveform > 8) {
					_shift_register &= 0x7fffff ^ (1 << 22) ^ (1 << 20) ^ (1 << 16)
							^ (1 << 13) ^ (1 << 11) ^ (1 << 7) ^ (1 << 4)
							^ (1 << 2);
				}
			}
			else
			{
				if (test_next != 0)
				{
					_accumulator = 0;
					_shift_register = 0;
				}
				else if (_test != 0)
				{
					_shift_register = 0x7ffff8;
				}
			}
			_test = test_next;
		}
		
		
		public function readOSC():int
		{
			return output >> 4;
		}
		
		public function reset():void
		{
			_accumulator = 0;
			if (Config.ANTTI_LANKILA_PATCH)
			{
				_shift_register = 0x7ffffc;
			}
			else
			{
				_shift_register = 0x7ffff8;
			}
			
			_freq = 0;
			_pw = 0;
			
			_test = 0;
			_ring_mod = 0;
			_sync = 0;
			
			_msb_rising = false;
		}
		
		[Inline]
		public final function clock():void
		{
			if (_test != 0) {
				return;
			}
			
			var accumulator_prev:int = _accumulator;
			
			_accumulator += _freq;
			_accumulator &= 0xffffff;
			
			_msb_rising = !((accumulator_prev & 0x800000) != 0)
					&& ((_accumulator & 0x800000) != 0);
					
			if (!((accumulator_prev & 0x080000) != 0)
					&& ((_accumulator & 0x080000) != 0))
			{
				var bit0:int = ((_shift_register >> 22) ^ (_shift_register >> 17)) & 0x1;
				_shift_register <<= 1;
				_shift_register &= 0x7fffff;
				_shift_register |= bit0;
			}
		}
		
		[Inline]
		public final function clockDelta(delta_t:int):void
		{
			if (_test != 0)
			{
				return;
			}
			
			var accumulator_prev:int = _accumulator;
			
			var delta_accumulator:int = delta_t * _freq;
			_accumulator += delta_accumulator;
			_accumulator &= 0xffffff;
			
			_msb_rising = !((accumulator_prev & 0x800000) != 0)
					&& ((_accumulator & 0x800000) != 0);
					
			var shift_period:int = 0x100000;
			
			while (delta_accumulator != 0) {
				if (delta_accumulator < shift_period)
				{
					shift_period = delta_accumulator;
					
					if (shift_period <= 0x080000)
					{
						if ((((_accumulator - shift_period) & 0x080000) != 0)
								|| !((_accumulator & 0x080000) != 0))
						{
							break;
						}
					}
					else
					{
						if ((((_accumulator - shift_period) & 0x080000) != 0)
								&& !((_accumulator & 0x080000) != 0))
						{
							break;
						}
					}
				}
				
				var bit0:int = ((_shift_register >> 22) ^ (_shift_register >> 17)) & 0x1;
				_shift_register <<= 1;
				_shift_register &= 0x7fffff;
				_shift_register |= bit0;
				
				delta_accumulator -= shift_period;
			}
		}
		
		[Inline]
		public final function synchronize():void
		{
			if (_msb_rising && (_sync_dest._sync != 0)
					&& !((_sync != 0) && _sync_source._msb_rising))
			{
				_sync_dest._accumulator = 0;
			}
		}
		
		[Inline]
		protected final function output____():int
		{
			return 0x000;
		}
		
		[Inline]
		protected final function output___T():int
		{
			var msb:int = ((_ring_mod != 0) ? _accumulator
					^ _sync_source._accumulator : _accumulator) & 0x800000;
			return (((msb != 0) ? ~_accumulator : _accumulator) >> 11) & 0xfff;
		}
		
		[Inline]
		protected final function output__S_():int
		{
			return _accumulator >> 12;
		}
		
		[Inline]
		protected final function output_P__():int
		{
			return ((_test != 0) || (_accumulator >> 12) >= _pw) ? 0xfff : 0x000;
		}
		
		[Inline]
		protected final function outputN___():int
		{
			return ((_shift_register & 0x400000) >> 11)
					| ((_shift_register & 0x100000) >> 10)
					| ((_shift_register & 0x010000) >> 7)
					| ((_shift_register & 0x002000) >> 5)
					| ((_shift_register & 0x000800) >> 4)
					| ((_shift_register & 0x000080) >> 1)
					| ((_shift_register & 0x000010) << 1)
					| ((_shift_register & 0x000004) << 2);
		}
		
		[Inline]
		protected final function output__ST():int
		{
			return _wave__ST[output__S_()] << 4;
		}
		
		[Inline]
		protected final function output_P_T():int
		{
			return (_wave_P_T[output___T() >> 1] << 4) & output_P__();
		}
		
		[Inline]
		protected final function output_PS_():int
		{
			return (_wave_PS_[output__S_()] << 4) & output_P__();
		}
		
		[Inline]
		protected final function output_PST():int
		{
			return (_wave_PST[output__S_()] << 4) & output_P__();
		}
		
		[Inline]
		protected final function outputN__T():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputN_S_():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputN_ST():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputNP__():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputNP_T():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputNPS_():int
		{
			return 0;
		}
		
		[Inline]
		protected final function outputNPST():int
		{
			return 0;
		}
		
		[Inline]
		public final function get output():int
		{
			switch (_waveform) {
			default:
			case 0x0:
				return output____();
			case 0x1:
				return output___T();
			case 0x2:
				return output__S_();
			case 0x3:
				return output__ST();
			case 0x4:
				return output_P__();
			case 0x5:
				return output_P_T();
			case 0x6:
				return output_PS_();
			case 0x7:
				return output_PST();
			case 0x8:
				return outputN___();
			case 0x9:
				return outputN__T();
			case 0xa:
				return outputN_S_();
			case 0xb:
				return outputN_ST();
			case 0xc:
				return outputNP__();
			case 0xd:
				return outputNP_T();
			case 0xe:
				return outputNPS_();
			case 0xf:
				return outputNPST();
			}
		}
		
		public function get freq():int 
		{
			return _freq;
		}
		
		public function get pw():int 
		{
			return _pw;
		}
		
		public function get waveform():int 
		{
			return _waveform;
		}
		
		public function get test():int 
		{
			return _test;
		}
		
		public function get ring_mod():int 
		{
			return _ring_mod;
		}
		
		public function get sync():int 
		{
			return _sync;
		}
		
		public function get sync_dest():WaveformGenerator 
		{
			return _sync_dest;
		}
		
		public function get sync_source():WaveformGenerator 
		{
			return _sync_source;
		}
		
		public function get accumulator():int 
		{
			return _accumulator;
		}
	}
}