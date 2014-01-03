package psid 
{
	import flash.utils.ByteArray;
	import psid.enum.SFXChipType;
	/**
	 * ...
	 * @author Gary Paluk - http://www.plugin.io
	 */
	public class Filter 
	{
		
		public static const SPLINE_BRUTE_FORCE:Boolean = false;
		
		protected const PI:Number = 3.1415926535897932385;
		
		protected var _enabled:Boolean;
		protected var _fc:int;
		protected var _res:int;
		protected var _filt:int;
		
		protected var _voice3off:int;
		protected var _hp_bp_lp:int;
		protected var _vol:int;
		protected var _mixer_DC:int;
		
		protected var _vhp:int;
		protected var _vbp:int;
		protected var _vlp:int;
		protected var _vnf:int;
		
		public var DLthreshold:int, DLsteepness:int;
		public var DHthreshold:int, DHsteepness:int;
		public var DLlp:int, DLbp:int, DLhp:int; // coefficients, 256 = 1.0
		public var DHlp:int, DHbp:int, DHhp:int;
		
		protected var _w0:int, _w0_ceil_1:int, _w0_ceil_dt:int;
		protected var _1024_div_Q:int;
		
		protected var _f0_6581:ByteArray = new ByteArray();//TODO 2048 length
		protected var _f0_8580:ByteArray = new ByteArray();//TODO 2048 length
		
		protected var _f0:ByteArray;
		
		protected static var _f0_points_6581:Array = [
			// -----FC----f-------FCHI-FCLO
			[ 0, 220 ], // 0x00 - repeated end point
			[ 0, 220 ], // 0x00
			[ 128, 230 ], // 0x10
			[ 256, 250 ], // 0x20
			[ 384, 300 ], // 0x30
			[ 512, 420 ], // 0x40
			[ 640, 780 ], // 0x50
			[ 768, 1600 ], // 0x60
			[ 832, 2300 ], // 0x68
			[ 896, 3200 ], // 0x70
			[ 960, 4300 ], // 0x78
			[ 992, 5000 ], // 0x7c
			[ 1008, 5400 ], // 0x7e
			[ 1016, 5700 ], // 0x7f
			[ 1023, 6000 ], // 0x7f 0x07
			[ 1023, 6000 ], // 0x7f 0x07 - discontinuity
			[ 1024, 4600 ], // 0x80 -
			[ 1024, 4600 ], // 0x80
			[ 1032, 4800 ], // 0x81
			[ 1056, 5300 ], // 0x84
			[ 1088, 6000 ], // 0x88
			[ 1120, 6600 ], // 0x8c
			[ 1152, 7200 ], // 0x90
			[ 1280, 9500 ], // 0xa0
			[ 1408, 12000 ], // 0xb0
			[ 1536, 14500 ], // 0xc0
			[ 1664, 16000 ], // 0xd0
			[ 1792, 17100 ], // 0xe0
			[ 1920, 17700 ], // 0xf0
			[ 2047, 18000 ], // 0xff 0x07
			[ 2047, 18000 ] // 0xff 0x07 - repeated end point
		];
		
		protected static var _f0_points_8580:Array = [
			// -----FC----f-------FCHI-FCLO
			[ 0, 0 ], // 0x00 - repeated end point
			[ 0, 0 ], // 0x00
			[ 128, 800 ], // 0x10
			[ 256, 1600 ], // 0x20
			[ 384, 2500 ], // 0x30
			[ 512, 3300 ], // 0x40
			[ 640, 4100 ], // 0x50
			[ 768, 4800 ], // 0x60
			[ 896, 5600 ], // 0x70
			[ 1024, 6500 ], // 0x80
			[ 1152, 7500 ], // 0x90
			[ 1280, 8400 ], // 0xa0
			[ 1408, 9200 ], // 0xb0
			[ 1536, 9800 ], // 0xc0
			[ 1664, 10500 ], // 0xd0
			[ 1792, 11000 ], // 0xe0
			[ 1920, 11700 ], // 0xf0
			[ 2047, 12500 ], // 0xff 0x07
			[ 2047, 12500 ] // 0xff 0x07 - repeated end point
		];
		
		protected var _f0_points:Array;
		protected var _f0_count:int;
		
		[Inline]
		public final function clock(voice1:int, voice2:int, voice3:int, ext_in:int):void
		{
			voice1 >>= 7;
			voice2 >>= 7;
			
			if ((_voice3off != 0) && ((_filt & 0x04) == 0)) {
				voice3 = 0;
			}
			else
			{
				voice3 >>= 7;
			}
			
			ext_in >>= 7;
			
			if (!_enabled) {
				_vnf = voice1 + voice2 + voice3 + ext_in;
				_vhp = _vbp = _vlp = 0;
				return;
			}
			
			var Vi:int = _vnf = 0;
			
			if (Config.ANTTI_LANKILA_PATCH)
			{
				if ((_filt & 1) != 0)
					Vi += voice1;
				else
					_vnf += voice1;
				if ((_filt & 2) != 0)
					Vi += voice2;
				else
					_vnf += voice2;
				if ((_filt & 4) != 0)
					Vi += voice3;
				else
					_vnf += voice3;
				if ((_filt & 8) != 0)
					Vi += ext_in;
				else
					_vnf += ext_in;
			}
			else
			{
				switch (_filt)
				{
					case 0x0:
						Vi = 0;
						_vnf = voice1 + voice2 + voice3 + ext_in;
						break;
					case 0x1:
						Vi = voice1;
						_vnf = voice2 + voice3 + ext_in;
						break;
					case 0x2:
						Vi = voice2;
						_vnf = voice1 + voice3 + ext_in;
						break;
					case 0x3:
						Vi = voice1 + voice2;
						_vnf = voice3 + ext_in;
						break;
					case 0x4:
						Vi = voice3;
						_vnf = voice1 + voice2 + ext_in;
						break;
					case 0x5:
						Vi = voice1 + voice3;
						_vnf = voice2 + ext_in;
						break;
					case 0x6:
						Vi = voice2 + voice3;
						_vnf = voice1 + ext_in;
						break;
					case 0x7:
						Vi = voice1 + voice2 + voice3;
						_vnf = ext_in;
						break;
					case 0x8:
						Vi = ext_in;
						_vnf = voice1 + voice2 + voice3;
						break;
					case 0x9:
						Vi = voice1 + ext_in;
						_vnf = voice2 + voice3;
						break;
					case 0xa:
						Vi = voice2 + ext_in;
						_vnf = voice1 + voice3;
						break;
					case 0xb:
						Vi = voice1 + voice2 + ext_in;
						_vnf = voice3;
						break;
					case 0xc:
						Vi = voice3 + ext_in;
						_vnf = voice1 + voice2;
						break;
					case 0xd:
						Vi = voice1 + voice3 + ext_in;
						_vnf = voice2;
						break;
					case 0xe:
						Vi = voice2 + voice3 + ext_in;
						_vnf = voice1;
						break;
					case 0xf:
						Vi = voice1 + voice2 + voice3 + ext_in;
						_vnf = 0;
						break;
				}
			}
			
			if (Config.ANTTI_LANKILA_PATCH)
			{
				var Vi_peak_bp:int = ((_vlp * DHlp + _vbp * DHbp + _vhp
						* DHhp) >> 8)
						+ Vi;
				if (Vi_peak_bp < DHthreshold)
					Vi_peak_bp = DHthreshold;
				var Vi_peak_lp:int = ((_vlp * DLlp + _vbp * DLbp + _vhp
						* DLhp) >> 8)
						+ Vi;
				if (Vi_peak_lp < DLthreshold)
					Vi_peak_lp = DLthreshold;
				var w0_eff_bp:int = _w0 + _w0
						* ((Vi_peak_bp - DHthreshold) >> 4) / DHsteepness;
				var w0_eff_lp:int = _w0 + _w0
						* ((Vi_peak_lp - DLthreshold) >> 4) / DLsteepness;
				
				if (w0_eff_bp > _w0_ceil_1)
				{
					w0_eff_bp = _w0_ceil_1;
				}
				if (w0_eff_lp > _w0_ceil_1)
				{
					w0_eff_lp = _w0_ceil_1;
				}
				_vhp = (_vbp * _1024_div_Q >> 10) - _vlp - Vi;
				_vlp -= w0_eff_lp * _vbp >> 20;
				_vbp -= w0_eff_bp * _vhp >> 20;
			} 
			else
			{
				var dVbp:int = (_w0_ceil_1 * _vhp >> 20);
				var dVlp:int = (_w0_ceil_1 * _vbp >> 20);
				_vbp -= dVbp;
				_vlp -= dVlp;
				_vhp = (_vbp * _1024_div_Q >> 10) - _vlp - Vi;
			}
		}
		
		[Inline]
		public final function clockDelta(delta_t:int,
						voice1:int, voice2:int,
						voice3:int, ext_in:int):void
		{
			voice1 >>= 7;
			voice2 >>= 7;
			
			if ((_voice3off != 0) && ((_filt & 0x04) == 0)) {
				voice3 = 0;
			} else {
				voice3 >>= 7;
			}
			ext_in >>= 7;
			
			if (!_enabled) {
				_vnf = voice1 + voice2 + voice3 + ext_in;
				_vhp = _vbp = _vlp = 0;
				return;
			}
			
			var Vi:int = _vnf = 0;
			
			if (!Config.ANTTI_LANKILA_PATCH)
			{
				switch (_filt)
				{
					case 0x0:
						Vi = 0;
						_vnf = voice1 + voice2 + voice3 + ext_in;
						break;
					case 0x1:
						Vi = voice1;
						_vnf = voice2 + voice3 + ext_in;
						break;
					case 0x2:
						Vi = voice2;
						_vnf = voice1 + voice3 + ext_in;
						break;
					case 0x3:
						Vi = voice1 + voice2;
						_vnf = voice3 + ext_in;
						break;
					case 0x4:
						Vi = voice3;
						_vnf = voice1 + voice2 + ext_in;
						break;
					case 0x5:
						Vi = voice1 + voice3;
						_vnf = voice2 + ext_in;
						break;
					case 0x6:
						Vi = voice2 + voice3;
						_vnf = voice1 + ext_in;
						break;
					case 0x7:
						Vi = voice1 + voice2 + voice3;
						_vnf = ext_in;
						break;
					case 0x8:
						Vi = ext_in;
						_vnf = voice1 + voice2 + voice3;
						break;
					case 0x9:
						Vi = voice1 + ext_in;
						_vnf = voice2 + voice3;
						break;
					case 0xa:
						Vi = voice2 + ext_in;
						_vnf = voice1 + voice3;
						break;
					case 0xb:
						Vi = voice1 + voice2 + ext_in;
						_vnf = voice3;
						break;
					case 0xc:
						Vi = voice3 + ext_in;
						_vnf = voice1 + voice2;
						break;
					case 0xd:
						Vi = voice1 + voice3 + ext_in;
						_vnf = voice2;
						break;
					case 0xe:
						Vi = voice2 + voice3 + ext_in;
						_vnf = voice1;
						break;
					case 0xf:
						Vi = voice1 + voice2 + voice3 + ext_in;
						_vnf = 0;
						break;
				}
			}
			else
			{
				if ((_filt & 1) != 0)
					Vi += voice1;
				else
					_vnf += voice1;
				if ((_filt & 2) != 0)
					Vi += voice2;
				else
					_vnf += voice2;
				if ((_filt & 4) != 0)
					Vi += voice3;
				else
					_vnf += voice3;
				if ((_filt & 8) != 0)
					Vi += ext_in;
				else
					_vnf += ext_in;
			}
			
			var delta_t_flt:int = 8;
			
			while (delta_t != 0)
			{
				if (delta_t < delta_t_flt)
				{
					delta_t_flt = delta_t;
				}
				
				var w0_delta_t:int = _w0_ceil_dt * delta_t_flt >> 6;
				
				var dVbp:int = (w0_delta_t * _vhp >> 14);
				var dVlp:int = (w0_delta_t * _vbp >> 14);
				_vbp -= dVbp;
				_vlp -= dVlp;
				_vhp = (_vbp * _1024_div_Q >> 10) - _vlp - Vi;
				
				delta_t -= delta_t_flt;
			}
		}
		
		public function get output():int
		{
			if (!_enabled) {
				return (_vnf + _mixer_DC) * (_vol);
			}
			
			var Vf:int;
			if (!Config.ANTTI_LANKILA_PATCH)
			{
				Vf = 0;
				switch (_hp_bp_lp)
				{
					case 0x0:
						Vf = 0;
						break;
					case 0x1:
						Vf = _vlp;
						break;
					case 0x2:
						Vf = _vbp;
						break;
					case 0x3:
						Vf = _vlp + _vbp;
						break;
					case 0x4:
						Vf = _vhp;
						break;
					case 0x5:
						Vf = _vlp + _vhp;
						break;
					case 0x6:
						Vf = _vbp + _vhp;
						break;
					case 0x7:
						Vf = _vlp + _vbp + _vhp;
						break;
				}
				return (_vnf + Vf + _mixer_DC) * (_vol);
			} else {
				Vf = 0;
				if ((_hp_bp_lp & 1) != 0)
					Vf += _vlp;
				if ((_hp_bp_lp & 2) != 0)
					Vf += _vbp;
				if ((_hp_bp_lp & 4) != 0)
					Vf += _vhp;
					
				return (_vnf + Vf + _mixer_DC) * (_vol);
			}
		}
		
		public function Filter() 
		{
			_fc = 0;
			_res = 0;
			_filt = 0;
			_voice3off = 0;
			_hp_bp_lp = 0;
			_vol = 0;
			
			_vhp = 0;
			_vbp = 0;
			_vlp = 0;
			_vnf = 0;
			
			enable_filter(true);
			
			interpolate(_f0_points_6581, 0, _f0_points_6581.length - 1,
					new PointPlotter(_f0_6581), 1.0);
			interpolate(_f0_points_8580, 0, _f0_points_8580.length - 1,
					new PointPlotter(_f0_8580), 1.0);
			
			set_chip_model(SFXChipType.MOS6581);
			
			set_distortion_properties(999999, 999999, 0, 0, 0, 999999, 999999, 0, 0, 0);
		}
		
		public function enable_filter(enable:Boolean):void
		{
			_enabled = enable;
		}
		
		public function set_chip_model(model:SFXChipType):void
		{
			if (model == SFXChipType.MOS6581)
			{
				_mixer_DC = -0xfff * 0xff / 18 >> 7;
				
				_f0 = _f0_6581;
				_f0_points = _f0_points_6581;
				_f0_count = _f0_points_6581.length;
			}
			else
			{
				_mixer_DC = 0;
				
				_f0 = _f0_8580;
				_f0_points = _f0_points_8580;
				_f0_count = _f0_points_8580.length;
			}
			set_w0();
			set_Q();
		}
		
		public function set_distortion_properties(Lthreshold:int, Lsteepness:int, Llp:int,
					Lbp:int, Lhp:int, Hthreshold:int, Hsteepness:int, Hlp:int, Hbp:int,
					Hhp:int):void
		{
			DLthreshold = Lthreshold;
			if (Lsteepness < 16)
				Lsteepness = 16; /* avoid division by zero */
			DLsteepness = Lsteepness >> 4;
			DLlp = Llp;
			DLbp = Lbp;
			DLhp = Lhp;
			
			DHthreshold = Hthreshold;
			if (Hsteepness < 16)
				Hsteepness = 16;
			DHsteepness = Hsteepness >> 4;
			DHlp = Hlp;
			DHbp = Hbp;
			DHhp = Hhp;
		}
		
		public function reset():void
		{
			_fc = 0;
			_res = 0;
			_filt = 0;
			_voice3off = 0;
			_hp_bp_lp = 0;
			_vol = 0;
			
			// State of filter.
			_vhp = 0;
			_vbp = 0;
			_vlp = 0;
			_vnf = 0;
			
			set_w0();
			set_Q();
		}
		
		public function writeFC_LO(fc_lo:int):void
		{
			_fc = _fc & 0x7f8 | fc_lo & 0x007;
			set_w0();
		}
		
		public function writeFC_HI(fc_hi:int):void
		{
			_fc = (fc_hi << 3) & 0x7f8 | _fc & 0x007;
			set_w0();
		}
		
		public function writeRES_FILT(res_filt:int):void
		{
			_res = (res_filt >> 4) & 0x0f;
			set_Q();
			_filt = res_filt & 0x0f;
		}
		
		public function writeMODE_VOL(mode_vol:int):void
		{
			_voice3off = mode_vol & 0x80;
			_hp_bp_lp = (mode_vol >> 4) & 0x07;
			_vol = mode_vol & 0x0f;
		}
		
		protected function set_w0():void
		{
			_w0 = int(2 * PI * _f0[_fc] * 1.048576);
			
			if (Config.ANTTI_LANKILA_PATCH)
			{
				_w0_ceil_1 = int(2 * PI * 18000 * 1.048576);
			}
			else
			{
				var w0_max_1:int = int(2 * PI * 16000 * 1.048576);
				_w0_ceil_1 = _w0 <= w0_max_1 ? _w0 : w0_max_1;
			}
			
			var w0_max_dt:int = int(2 * PI * 4000 * 1.048576);
			_w0_ceil_dt = _w0 <= w0_max_dt ? _w0 : w0_max_dt;
		}
		
		protected function set_Q():void
		{
			_1024_div_Q = int(1024.0 / (0.707 + 1.0 * _res / 0x0f));
		}
		
		public function fc_default(fcp:FCPoints):void
		{
			fcp.points = _f0_points;
			fcp.count = _f0_count;
		}
		
		public function get fc_plotter():PointPlotter
		{
			return new PointPlotter(_f0);
		}
		
		public function get fc():int 
		{
			return _fc;
		}
		
		public function get res():int 
		{
			return _res;
		}
		
		public function get filt():int 
		{
			return _filt;
		}
		
		public function get voice3off():int 
		{
			return _voice3off;
		}
		
		public function get hp_bp_lp():int 
		{
			return _hp_bp_lp;
		}
		
		public function get vol():int 
		{
			return _vol;
		}
		
		protected function cubic_coefficients(x1:Number, y1:Number, x2:Number,
				y2:Number, k1:Number, k2:Number, coeff:Coefficients):void
		{
			var dx:Number = x2 - x1, dy:Number = y2 - y1;
			
			coeff.a = ((k1 + k2) - 2 * dy / dx) / (dx * dx);
			coeff.b = ((k2 - k1) / dx - 3 * (x1 + x2) * coeff.a) / 2;
			coeff.c = k1 - (3 * x1 * coeff.a + 2 * coeff.b) * x1;
			coeff.d = y1 - ((x1 * coeff.a + coeff.b) * x1 + coeff.c) * x1;
		}
		
		protected function interpolate_brute_force(x1:Number, y1:Number, x2:Number,
				y2:Number, k1:Number, k2:Number, plotter:PointPlotter, res:Number):void
		{
			var coeff:Coefficients = new Coefficients();
			cubic_coefficients(x1, y1, x2, y2, k1, k2, coeff);
			
			for (var x:Number = x1; x <= x2; x += res)
			{
				var y:Number = ((coeff.a * x + coeff.b) * x + coeff.c) * x + coeff.d;
				plotter.plot(x, y);
			}
		}
		
		protected function interpolate_forward_difference(x1:Number, y1:Number,
				x2:Number, y2:Number, k1:Number, k2:Number, plotter:PointPlotter,
				res:Number):void
		{
			var coeff:Coefficients = new Coefficients();
			cubic_coefficients(x1, y1, x2, y2, k1, k2, coeff);
			
			var y:Number = ((coeff.a * x1 + coeff.b) * x1 + coeff.c) * x1 + coeff.d;
			var dy:Number = (3 * coeff.a * (x1 + res) + 2 * coeff.b) * x1 * res
					+ ((coeff.a * res + coeff.b) * res + coeff.c) * res;
			var d2y:Number = (6 * coeff.a * (x1 + res) + 2 * coeff.b) * res * res;
			var d3y:Number = 6 * coeff.a * res * res * res;
			
			for (var x:Number = x1; x <= x2; x += res) {
				plotter.plot(x, y);
				y += dy;
				dy += d2y;
				d2y += d3y;
			}
		}
		
		protected function x(f0_base:Array, p:int):Number
		{
			return (f0_base[p])[0];
		}
		
		protected function y(f0_base:Array, p:int):Number
		{
			return (f0_base[p])[1];
		}
		
		public function interpolate(f0_base:Array, p0:int, pn:int,
				plotter:PointPlotter, res:Number):void
		{
			var k1:Number, k2:Number;
			
			var p1:int = p0;
			++p1;
			var p2:int = p1;
			++p2;
			var p3:int = p2;
			++p3;
			
			for (; p2 != pn; ++p0, ++p1, ++p2, ++p3)
			{
				if (x(f0_base, p1) == x(f0_base, p2)) {
					continue;
				}
				if (x(f0_base, p0) == x(f0_base, p1)
						&& x(f0_base, p2) == x(f0_base, p3)) {
					k1 = k2 = (y(f0_base, p2) - y(f0_base, p1))
							/ (x(f0_base, p2) - x(f0_base, p1));
				}
				else if (x(f0_base, p0) == x(f0_base, p1)) {
					k2 = (y(f0_base, p3) - y(f0_base, p1))
							/ (x(f0_base, p3) - x(f0_base, p1));
					k1 = (3 * (y(f0_base, p2) - y(f0_base, p1))
							/ (x(f0_base, p2) - x(f0_base, p1)) - k2) / 2;
				}
				else if (x(f0_base, p2) == x(f0_base, p3)) {
					k1 = (y(f0_base, p2) - y(f0_base, p0))
							/ (x(f0_base, p2) - x(f0_base, p0));
					k2 = (3 * (y(f0_base, p2) - y(f0_base, p1))
							/ (x(f0_base, p2) - x(f0_base, p1)) - k1) / 2;
				}
				else {
					k1 = (y(f0_base, p2) - y(f0_base, p0))
							/ (x(f0_base, p2) - x(f0_base, p0));
					k2 = (y(f0_base, p3) - y(f0_base, p1))
							/ (x(f0_base, p3) - x(f0_base, p1));
				}
				if (SPLINE_BRUTE_FORCE) {
					interpolate_brute_force(x(f0_base, p1), y(f0_base, p1), x(
							f0_base, p2), y(f0_base, p2), k1, k2, plotter, res);
				} else {
					interpolate_forward_difference(x(f0_base, p1), y(f0_base, p1),
							x(f0_base, p2), y(f0_base, p2), k1, k2, plotter, res);
				}
			}
		}
	}

}