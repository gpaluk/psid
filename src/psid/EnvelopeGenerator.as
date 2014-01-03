package psid 
{
	import psid.states.EnvelopeState;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class EnvelopeGenerator 
	{
		
		protected var _rate_counter:int;
		protected var _rate_period:int;
		protected var _exponential_counter:int;
		protected var _exponential_counter_period:int;
		protected var _envelope_counter:int;
		protected var _hold_zero:Boolean;
		protected var _attack:int;
		protected var _decay:int;
		protected var _sustain:int;
		protected var _release:int;
		protected var _gate:int;
		
		protected var _state:EnvelopeState;
		
		protected static var _rate_counter_period:Array = [
			9, // 2ms*1.0MHz/256 = 7.81
			32, // 8ms*1.0MHz/256 = 31.25
			63, // 16ms*1.0MHz/256 = 62.50
			95, // 24ms*1.0MHz/256 = 93.75
			149, // 38ms*1.0MHz/256 = 148.44
			220, // 56ms*1.0MHz/256 = 218.75
			267, // 68ms*1.0MHz/256 = 265.63
			313, // 80ms*1.0MHz/256 = 312.50
			392, // 100ms*1.0MHz/256 = 390.63
			977, // 250ms*1.0MHz/256 = 976.56
			1954, // 500ms*1.0MHz/256 = 1953.13
			3126, // 800ms*1.0MHz/256 = 3125.00
			3907, // 1 s*1.0MHz/256 = 3906.25
			11720, // 3 s*1.0MHz/256 = 11718.75
			19532, // 5 s*1.0MHz/256 = 19531.25
			31251 // 8 s*1.0MHz/256 = 31250.00
		];
		
		protected static var _sustain_level:Array = [
			0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa,
			0xbb, 0xcc, 0xdd, 0xee, 0xff
		];
		
		public function EnvelopeGenerator() 
		{
			reset();
		}
		
		public function clock():void
		{
			if ((++_rate_counter & 0x8000) != 0)
			{
				++_rate_counter;
				_rate_counter &= 0x7fff;
			}
			
			if (_rate_counter != _rate_period)
			{
				return;
			}
			
			_rate_counter = 0;
			
			if (_state == EnvelopeState.ATTACK
				|| ++_exponential_counter == _exponential_counter_period)
			{
				_exponential_counter = 0;
				
				if (_hold_zero)
				{
					return;
				}
				
				if (_state == EnvelopeState.ATTACK)
				{
					++_envelope_counter;
					_envelope_counter &= 0xff;
					if (_envelope_counter == 0xff)
					{
						_state = EnvelopeState.DECAY_SUSTAIN;
						_rate_period = _rate_counter_period[_decay];
					}
				}
				else if (_state == EnvelopeState.DECAY_SUSTAIN)
				{
					if (_envelope_counter != _sustain_level[_sustain])
					{
						--_envelope_counter;
					}
				}
				else if (_state == EnvelopeState.RELEASE)
				{
					--_envelope_counter;
					_envelope_counter &= 0xff;
				}
				
				switch (_envelope_counter)
				{
					case 0xff:
						_exponential_counter_period = 1;
						break;
					case 0x5d:
						_exponential_counter_period = 2;
						break;
					case 0x36:
						_exponential_counter_period = 4;
						break;
					case 0x1a:
						_exponential_counter_period = 8;
						break;
					case 0x0e:
						_exponential_counter_period = 16;
						break;
					case 0x06:
						_exponential_counter_period = 30;
						break;
					case 0x00:
						_exponential_counter_period = 1;
						_hold_zero = true;
						break;
				}
			}
		}
		
		public function clockDelta( delta_t:int ):void
		{
			var rate_step:int = _rate_period - _rate_counter;
			if (rate_step <= 0)
			{
				rate_step += 0x7fff;
			}
			
			while (delta_t != 0)
			{
				if (delta_t < rate_step)
				{
					_rate_counter += delta_t;
					if ((_rate_counter & 0x8000) != 0)
					{
						++_rate_counter;
						_rate_counter &= 0x7fff;
					}
					return;
				}
				
				_rate_counter = 0;
				delta_t -= rate_step;
				
				if (_state == EnvelopeState.ATTACK
						|| ++_exponential_counter == _exponential_counter_period) {
					
					_exponential_counter = 0;
					
					if (_hold_zero)
					{
						rate_step = _rate_period;
						continue;
					}
					
					if (_state == EnvelopeState.ATTACK)
					{
						++_envelope_counter;
						_envelope_counter &= 0xff;
						if (_envelope_counter == 0xff)
						{
							_state = EnvelopeState.DECAY_SUSTAIN;
							_rate_period = _rate_counter_period[_decay];
						}
					}
					else if (_state == EnvelopeState.DECAY_SUSTAIN)
					{
						if (_envelope_counter != _sustain_level[_sustain])
						{
							--_envelope_counter;
						}
					}
					else if (_state == EnvelopeState.RELEASE)
					{
						--_envelope_counter;
						_envelope_counter &= 0xff;
					}
					
					switch (_envelope_counter)
					{
						case 0xff:
							_exponential_counter_period = 1;
							break;
						case 0x5d:
							_exponential_counter_period = 2;
							break;
						case 0x36:
							_exponential_counter_period = 4;
							break;
						case 0x1a:
							_exponential_counter_period = 8;
							break;
						case 0x0e:
							_exponential_counter_period = 16;
							break;
						case 0x06:
							_exponential_counter_period = 30;
							break;
						case 0x00:
							_exponential_counter_period = 1;
							_hold_zero = true;
							break;
					}
				}
				rate_step = _rate_period;
			}
		}
		
		public function get output():int
		{
			return _envelope_counter;
		}
		
		public function get gate():int 
		{
			return _gate;
		}
		
		public function get attack():int 
		{
			return _attack;
		}
		
		public function get decay():int 
		{
			return _decay;
		}
		
		public function get sustain():int 
		{
			return _sustain;
		}
		
		public function get release():int 
		{
			return _release;
		}
		
		public function reset():void
		{
			_envelope_counter = 0;
			
			_attack = 0;
			_decay = 0;
			_sustain = 0;
			_release = 0;
			
			_gate = 0;
			
			_rate_counter = 0;
			_exponential_counter = 0;
			_exponential_counter_period = 1;
			
			_state = EnvelopeState.RELEASE;
			_rate_period = _rate_counter_period[_release];
			_hold_zero = true;
		}
		
		public function writeCONTROL_REG(control:int):void
		{
			var gate_next:int = control & 0x01;
			
			if ((_gate == 0) && (gate_next != 0))
			{
				_state = EnvelopeState.ATTACK;
				_rate_period = _rate_counter_period[_attack];
				
				_hold_zero = false;
			}
			else if ((_gate != 0) && (gate_next == 0))
			{
				_state = EnvelopeState.RELEASE;
				_rate_period = _rate_counter_period[_release];
			}
			_gate = gate_next;
		}
		
		public function writeATTACK_DECAY(attack_decay:int):void
		{
			_attack = (attack_decay >> 4) & 0x0f;
			_decay = attack_decay & 0x0f;
			if (_state == EnvelopeState.ATTACK)
			{
				_rate_period = _rate_counter_period[_attack];
			}
			else if (_state == EnvelopeState.DECAY_SUSTAIN)
			{
				_rate_period = _rate_counter_period[_decay];
			}
		}
		
		public function writeSUSTAIN_RELEASE(sustain_release:int):void
		{
			_sustain = (sustain_release >> 4) & 0x0f;
			_release = sustain_release & 0x0f;
			if (_state == EnvelopeState.RELEASE)
			{
				_rate_period = _rate_counter_period[_release];
			}
		}
		
		public function readENV():int
		{
			return output;
		}
		
	}
}