/*
	************************************************
	
	FILE: SectorDialSmooth.as
	
	Copyright (c) 2004-2012, Jonathan Kaye, All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted
	provided that the following conditions are met:

	- Redistributions of source code must retain the above copyright notice, this list of conditions
	and the following disclaimer.
	- Redistributions in binary form must reproduce the above copyright notice, this list of conditions
	and the following disclaimer in the documentation and/or other materials provided with the distribution.
	- Neither the name of the Equipment Simulations LLC nor the names of its contributors may be used to endorse or
	promote products derived from this software without specific prior written permission. 
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
	USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	[Read more about this license at http://www.opensource.org/licenses/bsd-license.php]
	
	************************************************
*/

package com.eqsim.components { 
	
	[IconFile("icons/sdial.png")]
	
	/**
	Event generated when the needle reaches the target value (only after target value has been
	set using the <code>targVal</code> property).  Can be changed by setting the <code>evtReachTarg</code> property.

	@event onReachTarg
	*/
	[Event("onReachTarg")]
	
	
	
	import fl.core.UIComponent;
	import flash.utils.getDefinitionByName;
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.eqsim.events.EventWithData;
	import com.eqsim.components.SectorDial;

	
	/** ************************************************
	<p>This class is an extension of SectorDial that provides sector dial functionality
	with a rate-limited needle (based on a user-specified needle rate).  Developers can set its
	value in two ways.  First, by setting the <code>val</code> property to have the
	dial jump immediately to that value.  Second, by setting the <code>targVal</code>
	property, the dial will reach the target value based on the set needle rate (<code>needleRate</code>).
	For convenience, the gauge generates an event, <code>onReachTarg</code> when it reaches the target value (only if
	set using <code>targVal</code>).</p>

	<p>To simulate the smooth needle movement, this component updates the needle approximately every
	1/20th of a second (note: because it uses Flash's <code>Timer()</code> this interval can be up to twice as slow if the
	frame rate is set around 20 fps, due to "features" of the setInterval implementation).  Therefore,
	if you have more than a few of these components on the stage, you may find that it slows down other processes.  If
	you need many of these on the Stage at once, you might consider rewriting this to centralize the needle update and
	need for all the timers.</p>

	<p>Users can change the appearance of the
	hand by modifying: <code>defSectorDialHand</code>, 
	center of the dial by modifying: <code>defSectorDialCenter</code>,
	the background graphic by modifying: <code>defSectorDialBkgnd</code>.</p>

	<p>Showing the dial center and background are optional.</p>
	 * ************************************************* */
	public class SectorDialSmooth extends SectorDial {

		/* ***************************************************
		 * Exposed Properties
		 * *************************************************** */
		 
		/**
		Property that holds the string name of the event generated by this component.  This must
		be set through the component property panel or programmatically
		through the initObject parameter of attachMovie/createClassObject.
		@property evtReachTarg
		*/
		[Inspectable(name="onReachTarg method name", type=String, defaultValue="onReachTarg")]
		public var evtReachTarg:String = "onReachTarg";
			
		/**
		The rate the needle travels when the gauge is set using <code>targVal</code> property.  The
		rate is in units per second.  You can change this property to change the rate, but not during
		needle movement (in that case, use <code>setVal()</code> to fix the needle position, adjust
		the rate, and set the new target rate).
		@property needleRate
		*/
		[Inspectable(name="Needle rate (units/sec)", type=Number, defaultValue=10)]
		public function set needleRate (r:Number): void {
			_needleRate = r;
			if (_inX) {
				setTargVal(_targVal);
			}
		}
		
		public function get needleRate () : Number {
			return _needleRate;
		}
		protected var _needleRate:Number = 10;
		
		public function set targVal (v:Number) : void {
			setTargVal(v);
			_targVal = v;
		}
		public function get targVal () : Number {
			return _targVal;
		}
		protected var _targVal:Number;
	
		
		/* ***************************************************
		 * Protected/Private Properties
		 * *************************************************** */
		protected var _unitsPupd:Number; 	// units per update
		protected var _inX:Boolean; 		// whether or not currently transitioning
		protected var _xTimer:Timer; 		// Timer object for transitioning needle
		
		/* ***************************************************
		 * Constants
		 * *************************************************** */
		 
		/**
		 *
		 */
		

		/* ***************************************************
		 * Constructor and Required Methods (UIComponent)
		 * *************************************************** */ 

		/**
		 *
		 */
		public function SectorDialSmooth() {
			super();
		}
		 
		/**
		 * configUI
		 * Get the display objects created in preparation of launch.  Note that we get called before
		 * our constructor, and before we are notified that we are on the stage!
		 */
		override protected function configUI():void {
			super.configUI();
			
			_xTimer = new Timer(50, 0);
			_xTimer.addEventListener(TimerEvent.TIMER, xCbk);
			_inX = false;
		}
		
	
		/**
		 * 
		 */
		protected override function draw():void {
				
			// Last line must call superclass method
			super.draw();
		}
		
		
		/* ***************************************************
		 * Exposed Methods
		 * *************************************************** */
		 
		/**
		 *
		 */
		public function setTargVal (v:Number) : void {
			_unitsPupd = _needleRate / 20;
			if (v < _val) 
				_unitsPupd *= -1;

			if (!_inX && v != _val) {
				_xTimer.start();
				_inX = true;
			}
			_targVal = v;
		}
	
		/**
		 *
		 */
		[Inspectable(name="Starting value", type=Number, defaultValue=0)]
		public override function set val (v:Number) : void {
			if (_inX) {
				_xTimer.stop();
				_inX = false;
				_targVal = v;
			}
			setNeedle(v);
			_val = v;
		}
		
		public function destroy () : void {
			_xTimer.removeEventListener(TimerEvent.TIMER, xCbk);
		}
		 
		/* ***************************************************
		 * Private/Protected Methods
		 * *************************************************** */
		/**
		Used as callback to update the needle based on increment appropriate for set needle speed.
		@method xCbk
		@access private
		*/
		protected function xCbk (te:TimerEvent) : void {
				var curVal:Number = _val + _unitsPupd, diff:int;

				if (enabled) {
					diff = Math.abs(curVal - _targVal);
					if (diff < Math.abs(_unitsPupd)) {
						_xTimer.stop();
						_inX = false;
						curVal = _val = _targVal;
						
						dispatchEvent(new EventWithData(evtReachTarg, false, false, curVal));
					}
					
					setNeedle(curVal);
					_val = curVal;
				}
			}

		
	
	}
}