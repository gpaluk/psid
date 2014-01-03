package psid 
{
	import psid.enum.SampleType;
	import psid.enum.SFXChipType;
	import psid.states.EnvelopeState;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class SID 
	{
		
		private static const PI:Number = 3.1415926535897932385;
		
		protected var _voice:Array = [ new Voice(), new Voice(), new Voice() ];
		public var filter:Filter = new Filter();
		
		protected var _extfilt:ExternalFilter = new ExternalFilter();
		protected var _potx:Potentiometer = new Potentiometer();
		protected var _poty:Potentiometer = new Potentiometer();
		
		protected var _bus_value:int;
		protected var _bus_value_ttl:int;
		protected var _clock_frequency:Number;
		
		protected var _ext_in:int;
		
		protected static const FIR_N:int = 125;
		protected static const FIR_RES_INTERPOLATE:int = 285;
		protected static const FIR_RES_FAST:int = 51473;
		protected static const FIR_SHIFT:int = 15;
		protected static const RINGSIZE:int = 16384;
		protected static const FIXP_SHIFT:int = 16;
		protected static const FIXP_MASK:int = 0xffff;
		
		protected var _sampling:SampleType;
		protected var _cycles_per_sample:int;
		protected var _sample_offset:int;
		protected var _sample_index:int;
		protected var _sample_prev:int; //TODO mask short
		protected var _fir_N:int;
		protected var _fir_RES:int;
		protected var _sample:Array; //TODO mask shorts / ByteArray
		
		protected var _fir:Array; //TODO mask shorts / ByteArray
		
		public function SID() 
		{
			_sample = null;
			_fir = null;
			
			_voice[0].set_sync_source(_voice[2]);
			_voice[1].set_sync_source(_voice[0]);
			_voice[2].set_sync_source(_voice[1]);
			
			set_sampling_parameters(985248, SampleType.FAST, 44100, -1, 0.97);
			
			_bus_value = 0;
			_bus_value_ttl = 0;
			
			_ext_in = 0;
		}
		
		public function set_chip_model(model:SFXChipType):void
		{
			for (var i:int = 0; i < 3; i++)
			{
				_voice[i].set_chip_model(model);
			}
			
			filter.set_chip_model(model);
			_extfilt.set_chip_model(model);
		}
		
		public function set_distortion_properties(Lt:int, Ls:int, Ll:int, Lb:int,
				Lh:int, Ht:int, Hs:int, Hl:int, Hb:int, Hh:int):void
		{
			filter.set_distortion_properties(Lt, Ls, Ll, Lb, Lh, Ht, Hs, Hl, Hb, Hh);
		}
		
		public function reset():void
		{
			for (var i:int = 0; i < 3; i++)
			{
				_voice[i].reset();
			}
			filter.reset();
			_extfilt.reset();
			
			_bus_value = 0;
			_bus_value_ttl = 0;
		}
		
		public function input(sample:int):void
		{
			_ext_in = (sample << 4) * 3;
		}
		
		public function get output():int
		{
			var range:int = 1 << 16;
			var half:int = range >> 1;
			var sample:int = _extfilt.output / ((4095 * 255 >> 7) * 3 * 15 * 2 / range);
			if (sample >= half)
			{
				return half - 1;
			}
			if (sample < -half)
			{
				return -half;
			}
			return sample;
		}
		
		public function read(offset:int):int {
			switch (offset) {
				case 0x19:
					return _potx.readPOT();
				case 0x1a:
					return _poty.readPOT();
				case 0x1b:
					return _voice[2].wave.readOSC();
				case 0x1c:
					return _voice[2].envelope.readENV();
				default:
					return _bus_value;
			}
		}
		
		public function write(offset:int, value:int):void
		{
			_bus_value = value;
			_bus_value_ttl = 0x2000;
			
			switch (offset)
			{
			case 0x00:
				_voice[0].wave.writeFREQ_LO(value);
				break;
			case 0x01:
				_voice[0].wave.writeFREQ_HI(value);
				break;
			case 0x02:
				_voice[0].wave.writePW_LO(value);
				break;
			case 0x03:
				_voice[0].wave.writePW_HI(value);
				break;
			case 0x04:
				_voice[0].writeCONTROL_REG(value);
				break;
			case 0x05:
				_voice[0].envelope.writeATTACK_DECAY(value);
				break;
			case 0x06:
				_voice[0].envelope.writeSUSTAIN_RELEASE(value);
				break;
			case 0x07:
				_voice[1].wave.writeFREQ_LO(value);
				break;
			case 0x08:
				_voice[1].wave.writeFREQ_HI(value);
				break;
			case 0x09:
				_voice[1].wave.writePW_LO(value);
				break;
			case 0x0a:
				_voice[1].wave.writePW_HI(value);
				break;
			case 0x0b:
				_voice[1].writeCONTROL_REG(value);
				break;
			case 0x0c:
				_voice[1].envelope.writeATTACK_DECAY(value);
				break;
			case 0x0d:
				_voice[1].envelope.writeSUSTAIN_RELEASE(value);
				break;
			case 0x0e:
				_voice[2].wave.writeFREQ_LO(value);
				break;
			case 0x0f:
				_voice[2].wave.writeFREQ_HI(value);
				break;
			case 0x10:
				_voice[2].wave.writePW_LO(value);
				break;
			case 0x11:
				_voice[2].wave.writePW_HI(value);
				break;
			case 0x12:
				_voice[2].writeCONTROL_REG(value);
				break;
			case 0x13:
				_voice[2].envelope.writeATTACK_DECAY(value);
				break;
			case 0x14:
				_voice[2].envelope.writeSUSTAIN_RELEASE(value);
				break;
			case 0x15:
				filter.writeFC_LO(value);
				break;
			case 0x16:
				filter.writeFC_HI(value);
				break;
			case 0x17:
				filter.writeRES_FILT(value);
				break;
			case 0x18:
				filter.writeMODE_VOL(value);
				break;
			default:
				break;
			}
		}
		
		public function mute(channel:int, enable:Boolean):void
		{
			if (channel >= 3)
			{
				return;
			}
			_voice[channel].mute(enable);
		}
		
		public function read_state():State {
			var state:State = new State();
			var i:int, j:int;
			
			for (i = 0, j = 0; i < 3; i++, j += 7) {
				var wave:WaveformGenerator = _voice[i].wave;
				var envelope:EnvelopeGenerator = _voice[i].envelope;
				state.sid_register[j + 0] = (wave.freq & 0xff) & 0xFF;
				state.sid_register[j + 1] = (wave.freq >> 8) & 0xFF;
				state.sid_register[j + 2] = (wave.pw & 0xff) & 0xFF;
				state.sid_register[j + 3] = (wave.pw >> 8) & 0xFF;
				state.sid_register[j + 4] = ((wave.waveform << 4)
						| ((wave.test != 0) ? 0x08 : 0)
						| ((wave.ring_mod != 0) ? 0x04 : 0)
						| ((wave.sync != 0) ? 0x02 : 0) & 0xFF | ((envelope.gate != 0)  ? 0x01
						: 0));
				state.sid_register[j + 5] = ((envelope.attack << 4) | envelope.decay) & 0xFF;
				state.sid_register[j + 6] = ((envelope.sustain << 4) | envelope.release) & 0xFF;
			}
			
			state.sid_register[j++] = (filter.fc & 0x007) & 0xFF ;
			state.sid_register[j++] = (filter.fc >> 3) & 0xFF;
			state.sid_register[j++] = ((filter.res << 4) | filter.filt) & 0xFF;
			state.sid_register[j++] = (((filter.voice3off != 0) ? 0x80 : 0)
					| (filter.hp_bp_lp << 4) | filter.vol) & 0xFF;
			
			for (; j < 0x1d; j++) {
				state.sid_register[j] = (read(j) & 0xFF);
			}
			for (; j < 0x20; j++) {
				state.sid_register[j] = 0;
			}
			
			state.bus_value = _bus_value;
			state.bus_value_ttl = _bus_value_ttl;
			
			for (i = 0; i < 3; i++) {
				state.accumulator[i] = _voice[i].wave.accumulator;
				state.shift_register[i] = _voice[i].wave.shift_register;
				state.rate_counter[i] = _voice[i].envelope.rate_counter;
				state.rate_counter_period[i] = _voice[i].envelope.rate_period;
				state.exponential_counter[i] = _voice[i].envelope.exponential_counter;
				state.exponential_counter_period[i] = _voice[i].envelope.exponential_counter_period;
				state.envelope_counter[i] = _voice[i].envelope.envelope_counter;
				state.envelope_state[i] = _voice[i].envelope.state;
				state.hold_zero[i] = _voice[i].envelope.hold_zero;
			}
			return state;
		}
		
		public function write_state(state:State):void {
			var i:int;
			
			for (i = 0; i <= 0x18; i++) {
				write(i, state.sid_register[i]);
			}
			
			_bus_value = state.bus_value;
			_bus_value_ttl = state.bus_value_ttl;
			
			for (i = 0; i < 3; i++) {
				_voice[i].wave.accumulator = state.accumulator[i];
				_voice[i].wave.shift_register = state.shift_register[i];
				_voice[i].envelope.rate_counter = state.rate_counter[i];
				_voice[i].envelope.rate_period = state.rate_counter_period[i];
				_voice[i].envelope.exponential_counter = state.exponential_counter[i];
				_voice[i].envelope.exponential_counter_period = state.exponential_counter_period[i];
				_voice[i].envelope.envelope_counter = state.envelope_counter[i];
				_voice[i].envelope.state = state.envelope_state[i];
				_voice[i].envelope.hold_zero = state.hold_zero[i];
			}
		}
		
		public function enable_filter(enable:Boolean):void
		{
			filter.enable_filter(enable);
		}
		
		public function enable_external_filter(enable:Boolean):void
		{
			_extfilt.enable_filter(enable);
		}
		
		protected function I0(x:Number):Number
		{
			var I0e:Number = 1e-6;
			
			var sum:Number = 0, u:Number = 0, halfx:Number = 0, temp:Number = 0;
			var n:int;
			
			sum = u = n = 1;
			halfx = x / 2.0;
			
			do {
				temp = halfx / n++;
				u *= temp * temp;
				sum += u;
			} while (u >= I0e * sum);
			
			return sum;
		}
		
		public function set_sampling_parameters(clock_freq:Number,
				method:SampleType, sample_freq:Number, pass_freq:Number,
				filter_scale:Number):Boolean
		{
			var j:int;
			
			if (method == SampleType.RESAMPLE_INTERPOLATE
					|| method == SampleType.RESAMPLE_FAST)
			{
				if (FIR_N * clock_freq / sample_freq >= RINGSIZE)
				{
					return false;
				}
			}
			if (pass_freq < 0) {
				pass_freq = 20000;
				if (2 * pass_freq / sample_freq >= 0.9) {
					pass_freq = 0.9 * sample_freq / 2;
				}
			}
			else if (pass_freq > 0.9 * sample_freq / 2) {
				return false;
			}
			
			if (filter_scale < 0.9 || filter_scale > 1.0) {
				return false;
			}
			
			_extfilt.set_sampling_parameter(pass_freq);
			_clock_frequency = clock_freq;
			_sampling = method;
			
			_cycles_per_sample = int(clock_freq / sample_freq * (1 << FIXP_SHIFT) + 0.5);
			
			_sample_offset = 0;
			_sample_prev = 0;
			
			if (method != SampleType.RESAMPLE_INTERPOLATE
					&& method != SampleType.RESAMPLE_FAST)
			{
				_sample = null;
				_fir = null;
				return true;
			}
			
			// 16 bits -> -96dB stopband attenuation.
			var A:Number = -20 * log10(1.0 / (1 << 16));
			var dw:Number = (1 - 2 * pass_freq / sample_freq) * PI;
			var wc:Number = (2 * pass_freq / sample_freq + 1) * PI / 2;
			
			var beta:Number = 0.1102 * (A - 8.7);
			var I0beta:Number = I0(beta);
			
			var N:int = (int) ((A - 7.95) / (2.285 * dw) + 0.5);
			N += N & 1;
			
			var f_samples_per_cycle:Number = sample_freq / clock_freq;
			var f_cycles_per_sample:Number = clock_freq / sample_freq;
			
			_fir_N = int(N * f_cycles_per_sample) + 1;
			_fir_N |= 1;
			
			var res:int = method == SampleType.RESAMPLE_INTERPOLATE ? FIR_RES_INTERPOLATE : FIR_RES_FAST;
			var n:int = int( Math.ceil(Math.log(res / f_cycles_per_sample) / Math.log(2)));
			_fir_RES = 1 << n;
			
			_fir = null;
			_fir = new Array(_fir_N * _fir_RES)//shorts;
			
			for (var i:int = 0; i < _fir_RES; i++)
			{
				var fir_offset:int = i * _fir_N + _fir_N / 2;
				var j_offset:Number = (i) / _fir_RES;
				for (j = -_fir_N / 2; j <= _fir_N / 2; j++)
				{
					var jx:Number = j - j_offset;
					var wt:Number = wc * jx / f_cycles_per_sample;
					var temp:Number = jx / (_fir_N / 2);
					var Kaiser:Number = Math.abs(temp) <= 1 ? I0(beta * Math.sqrt(1 - temp * temp)) / I0beta : 0;
					var sincwt:Number = Math.abs(wt) >= 1e-6 ? Math.sin(wt) / wt : 1;
					var val:Number = (1 << FIR_SHIFT) * filter_scale * f_samples_per_cycle * wc / PI * sincwt * Kaiser;
					_fir[fir_offset + j] = (val + 0.5) & 0xFF;
				}
			}
			
			if ((_sample == null)) {
				_sample = new Array( RINGSIZE * 2);
			}
			
			for (j = 0; j < RINGSIZE * 2; j++) {
				_sample[j] = 0;
			}
			_sample_index = 0;
			
			return true;
		}
		
		public function adjust_sampling_frequency(sample_freq:Number):void
		{
			_cycles_per_sample = int(_clock_frequency / sample_freq * (1 << FIXP_SHIFT) + 0.5);
		}
		
		public function fc_default(fcp:FCPoints):void
		{
			filter.fc_default(fcp);
		}
		
		public function get fc_plotter():PointPlotter
		{
			return filter.fc_plotter;
		}
		
		public function clock():void
		{
			var i:int;
			
			if (--_bus_value_ttl <= 0) {
				_bus_value = 0;
				_bus_value_ttl = 0;
			}
			
			for (i = 0; i < 3; i++) {
				_voice[i].envelope.clock();
			}
			
			for (i = 0; i < 3; i++) {
				_voice[i].wave.clock();
			}
			
			for (i = 0; i < 3; i++) {
				_voice[i].wave.synchronize();
			}
			
			filter.clock(_voice[0].output(), _voice[1].output(), _voice[2].output(), _ext_in);
			
			_extfilt.clock(filter.output);
		}
		
		public function clockDelta(delta_t:int):void
		{
			var i:int;
			
			if (delta_t <= 0)
			{
				return;
			}
			
			_bus_value_ttl -= delta_t;
			if (_bus_value_ttl <= 0) {
				_bus_value = 0;
				_bus_value_ttl = 0;
			}
			
			for (i = 0; i < 3; i++) {
				_voice[i].envelope.clock(delta_t);
			}
			
			var delta_t_osc:int = delta_t;
			while (delta_t_osc != 0)
			{
				var delta_t_min:int = delta_t_osc;
				for (i = 0; i < 3; i++)
				{
					var wave:WaveformGenerator = _voice[i].wave;
					
					if (!((wave.sync_dest.sync != 0) && (wave.freq != 0))) {
						continue;
					}
					var freq:int = wave.freq;
					var accumulator:int = wave.accumulator;
					
					var delta_accumulator:int = ((accumulator & 0x800000) != 0 ? 0x1000000
							: 0x800000)
							- accumulator;
					var delta_t_next:int = (delta_accumulator / freq);
					if ((delta_accumulator % freq) != 0)
					{
						++delta_t_next;
					}
					
					if (delta_t_next < delta_t_min)
					{
						delta_t_min = delta_t_next;
					}
				}
				
				for (i = 0; i < 3; i++) {
					_voice[i].wave.clock(delta_t_min);
				}
				
				for (i = 0; i < 3; i++) {
					_voice[i].wave.synchronize();
				}
				
				delta_t_osc -= delta_t_min;
			}
			
			filter.clockDelta(delta_t, _voice[0].output, _voice[1].output, _voice[2].output, _ext_in);
			
			_extfilt.clockDelta(delta_t, filter.output);
		}
		
		private function log10(val:Number):Number
		{
			return Math.log(val) * 0.434294481904;
		}
		
	}

}

import psid.states.EnvelopeState;

internal class State
{
	public var sid_register:Array = new Array(0x20);
	public var bus_value:int;
	public var bus_value_ttl:int;
	public var accumulator:Array = new Array(3);
	public var shift_register:Array = new Array(3);
	public var rate_counter:Array = new Array(3);
	public var rate_counter_period:Array = new Array(3);
	public var exponential_counter:Array = new Array(3);
	public var exponential_counter_period:Array = new Array(3);
	
	public var envelope_counter:Array = new Array(3);
	public var envelope_state:Array = new Array(3);
	
	public var hold_zero:Array = new Array(3);
	
	/**
	 * Constructor.
	 */
	public function State()
	{
		var i:int;
		
		for (i = 0; i < 0x20; i++) {
			sid_register[i] = 0;
		}
		
		bus_value = 0;
		bus_value_ttl = 0;
		
		for (i = 0; i < 3; i++)
		{
			accumulator[i] = 0;
			shift_register[i] = 0x7ffff8;
			rate_counter[i] = 0;
			rate_counter_period[i] = 9;
			exponential_counter[i] = 0;
			exponential_counter_period[i] = 1;
			envelope_counter[i] = 0;
			envelope_state[i] = EnvelopeState.RELEASE;
			hold_zero[i] = true;
		}
	}
}

internal class CycleCount
{
		public function CycleCount(delta_t2:int)
		{
			delta_t = delta_t2;
		}
		public var delta_t:int;
	}