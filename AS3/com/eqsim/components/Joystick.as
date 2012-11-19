﻿/*
	************************************************

	FILE: Joystick.as
	
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
	
	import fl.core.UIComponent;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	import flash.utils.setInterval;
	import flash.utils.clearInterval;
	import flash.geom.Point;
	import flash.media.Sound;
	import com.eqsim.events.EventWithData;

[IconFile("joystick.png")]

/**
Event generated when joystick changes position -- either being moved, or on its way
back to center after being released.
@event onValChg
*/
[Event("onJChg")]
/**
Event generated when joystick knob is set as <code>enabled == false</code>.  You can change the name of the event in the <code>evtDisabled</code> property.
@event onDisabled
*/
[Event("onDisabled")]
/**
Event generated when joystick is away from the center position, at the specified
pulse frequency.
@event onJPulse
*/
[Event("onJPulse")]
/**
Event generated when the joystick has returned to the center position.
@event onJReturned
*/
[Event("onJReturned")]
/**
Event generated when the user (or programmatic control) starts to move the joystick.
@event onJStart
*/
[Event("onJStart")]
/**
Event generated when the user (or programmatic control) releases the joystick.
@event onJReleased
*/
[Event("onJReleased")]

	/** ************************************************
	<p>This class implements a continuous-valued joystick (but can be set for integers, as well).  The joystick x,y values range from
	<code>-maxVal</code> to <code>maxVal</code>, with 0 being the center.  The graphics should be set such that
	hot spot is in the topmost position and the stick is fully extended upwards.  The
	joystick uses these pixel values to compute its possible range.</p>

	<p>The routines allow the user to move the hot spot and the stick is rotated to the proper
	angle and scaled, from 0 (at center pos) to its fully extended position at
	<code>maxVal</code> (which the user can set).  Whenever the joystick is not in the center
	position, it generates an event (pulse), at a given frequency.  A property, <code>forceInt</code>, says whether
	to report the value as a floating point number or rounded integer.  The default event
	message is "onJChg".  When the user releases the joystick and it has returned to the center position, it generates a second
	event, by default, "onJReturned" (in addition to the <code>onJChg</code> event with coordinates
	[0, 0]).  Note that if the user does not release the joystick and passes over (0, 0), then the
	onJChg event is generated by not onJReturned.</p>
	 
	<p>The joystick snaps back to the center when it released, and a coefficient says
	how quickly this happens.</p>

	<p>The joystick can be controlled using the mouse or programmatically.  To use the mouse,
	the user drags the hotspot.  To use it programmatically, the caller invokes <code>moveHS(null, false)</code>, then uses <code>setVec()</code> to set the vector, and
	when done, uses <code>stopMoveHS(null, false)</code> to release the joystick.</p>

	<p>You can change the graphics by setting baseClassName, stickClassName, or hotspotClassName</p>
	 
	<li><code>defJStkBase</code> - background graphic for the joystick</li>
	<li><code>defJStkHotSpot</code> - handle (hot spot) for the joystick</li>
	<li><code>defJStkStick</code> - stick of the joystick</li>
	 * ************************************************* */
	public class Joystick extends UIComponent {

		/* ***************************************************
		 * Exposed Properties
		 * *************************************************** */
		 
		/**
		The event name for the joystick value change event.
		@property evtJChg
		*/
		[Inspectable(name="onJChg method name", type=String, defaultValue="onJChg")]
		public var evtJChg:String = "onJChg";
		
		[Inspectable(name="onJPulse method name", type=String, defaultValue="onJPulse")]
		public var evtJPulse:String = "onJPulse";
		
		/**
		The event name for the joystick "returned to center" event.  This event is
		generated when the joystick has been released by the user and it has returned to the center position (0, 0).
		@property evtJReturned
		*/
		[Inspectable(name="onJReturned method name", type=String, defaultValue="onJReturned")]
		public var evtJReturned:String = "onJReturned";

		/**
		The event name for the joystick "begin movement".  This event is
		generated when the joystick has been engaged.
		@property evtJStart
		*/
		[Inspectable(name="onJStart method name", type=String, defaultValue="onJStart")]
		public var evtJStart:String = "onJStart";
		
		/**
		The event name for the event generated when the user releases the joystick.
		@property evtJReleased
		*/
		[Inspectable(name="onJReleased method name", type=String, defaultValue="onJReleased")]
		public var evtJReleased:String = "onJReleased";
		
		/**
		 * Let user change the event names, if desired.
		 * The event name has to be set at the time the component is instantiated (either
		 * at run-time, or programmatically).
		 * @property
		 */
		[Inspectable(name="onDisabled method name", type=String, defaultValue="onDisabled")]
		public var evtDisabled:String = "onDisabled";

		/**
		 * Class name of the joystick base skin
		 * @property
		 */
		[Inspectable(name="Joystick Base Class Name", type=String, defaultValue="defJStkBase")]
		public function set baseClassName (v:String) : void {
			changeBase(v);
		}
		public function get baseClassName () : String {
			return (_baseClassName);
		}
		protected var _baseClassName:String = "defJStkBase";
		
		/**
		 * Class name of the joystick stick skin
		 * @property
		 */
		[Inspectable(name="Joystick Stick Class Name", type=String, defaultValue="defJStkStick")]
		public function set stickClassName (v:String) : void {
			changeStick(v);
		}
		public function get stickClassName () : String {
			return (_stickClassName);
		}
		protected var _stickClassName:String = "defJStkStick";
		
		/**
		 * Class name of the joystick hot spot skin
		 * @property
		 */
		[Inspectable(name="Joystick Hot Spot Class Name", type=String, defaultValue="defJStkHotSpot")]
		public function set hotspotClassName (v:String) : void {
			changeHotspot(v);
		}
		public function get hotspotClassName () : String {
			return (_hotspotClassName);
		}
		protected var _hotspotClassName:String = "defJStkHotSpot";
		
		
		/**
		Any value less than this is considered zero.  This is used so the person
		doesn't have to hit 0 exactly.  Usually about 5-10% of <code>maxVal</code>.
		
		@property centerEPS
		*/
		[Inspectable(name="Center allowance", type=Number, defaultValue=2)]
		public function set centerEPS (v) {
			_centerEPS = v;
			resetCenter();
		}
		public function get centerEPS () {
			return _centerEPS;
		}
		protected var _centerEPS:Number = 2;
		
		/**
		Whether or not the vector values generated in joystick events should be rounded to integers.
		
		@property forceInt
		*/
		[Inspectable(name="Force values to integer", type=Boolean, defaultValue=true)]
		public var forceInt:Boolean = true;

		/**
		Coefficient (between 0 and 1, inclusive) that determines how slowly the joystick
		returns to center once released.  0 is instantaneous, 1 means the joystick remains
		in the position left when the joystick was released (ultimate stickiness!).
		
		@property kSticky
		*/
		[Inspectable(name="Stickiness (0-1)", type=Number, defaultValue=0.6)]
		public function set kSticky (v) {
			_kSticky = Math.min(1, Math.max(0, v));
		}
		public function get kSticky () {
			return _kSticky;
		}
		protected var _kSticky:Number = 0.6;

		/**
		Frequency of events generated when the joystick is away from center position.
		
		@property pulseFreq
		*/
		[Inspectable(name="Event pulse frequency (msec)", type=Number, defaultValue=100)]
		public function set pulseFreq (v) {
			chgPulseFreq(v);
		}
		
		public function get pulseFreq () {
			return _pulseFreq;
		}
		protected var _pulseFreq:Number;
		protected var _pulseID:Number;
		
		/**
		If we should generate value pulses when the joystick is away from center position.
		
		@property generatePulseEvent
		*/
		[Inspectable(name="Generate pulse events", type=Boolean, defaultValue=false)]
		public function set generatePulseEvent (v:Boolean) : void {
			_genPulseEvent = v;
		}
		
		public function get generatePulseEvent () : Boolean {
			return _genPulseEvent;
		}
		protected var _genPulseEvent:Boolean = false;
		
		/**
		Maximum value for the vector coordinates when the joystick is at full extension.  The
		joystick center is always 0 (for both x and y coordinates), and this property sets
		the maximum value for the coordinate.  The maximum is used to set positive and negative
		extent, so joystick range will be (-maxVal,-maxVal) to (maxVal, maxVal).
		
		@property maxVal
		*/
		[Inspectable(name="Max value", type=Number, defaultValue=100)]
		public function set maxVal (v) {
			_maxVal = v;
			resetCenter();
		}
		public function get maxVal () {
			return _maxVal;
		}
		protected var _maxVal:Number = 100;
		
		/**
		Boolean property indicating whether or not to display the hand cursor when the cursor is
		over the hit area of this component.
		@property showHand
		*/
		[Inspectable(name="Show Hand Cursor", type=Boolean, defaultValue=true)]
		public function set showHand (f) {
			useHandCursor = f;
			_showHand = f;
		}
		public function get showHand () {
			return(_showHand);
		}
		protected var _showHand:Boolean = true;
		
		
		/* ***************************************************
		 * Protected/protected Properties
		 * *************************************************** */
		
		protected var baseClip:Sprite;
		protected var stickClip:Sprite;
		protected var hotspotClip:Sprite;
		protected var joystickContainer:Sprite;
		
		public var allowEvents:Boolean;
		
		// ptObj used to return x,y value to listeners
		protected var ptObj:Point = new Point(0, 0);
		
		// exact position of hotspot
		protected var hsExactX:Number;
		protected var hsExactY:Number;
		
		protected var limit:Number;
		
		protected var centerPx:Number;
		protected var stickLen:Number;
		
		protected var zeroCall:Boolean;
		protected var active:Boolean;
		
		protected var eventObj:Object;
		
		
		
		/* ***************************************************
		 * Constants
		 * *************************************************** */
		static protected const JOYSTICK_WIDTH:int = 160;

		/* ***************************************************
		 * Constructor and Required Methods (UIComponent)
		 * *************************************************** */ 

		/**
		 *
		 */
		public function Joystick() {
			super();
		}
		 
		/**
		 * configUI
		 * Get the display objects created in preparation of launch.  Note that we get called before
		 * our constructor, and before we are notified that we are on the stage!
		 */
		override protected function configUI():void {
			super.configUI();
			
			joystickContainer = new Sprite();
			changeBase(_baseClassName);
			changeStick(_stickClassName);
			changeHotspot(_hotspotClassName);
			
			allowEvents = true;
			eventObj = {};
			
			addChild(joystickContainer);
			
			addEventListener(Event.REMOVED_FROM_STAGE, catchNoStagePtr);
		}
		
		/**
		 * We use the draw method for initializing the position and size of the joystick parts, particularly
		 * when the developer has changed the default skins.
		 */
		override protected function draw () : void {
			// record joystick limit based on end position of joystick stick
			// limit = Math.sqrt(hotspotClip.x * hotspotClip.x + hotspotClip.y * hotspotClip.y);
			limit = Math.sqrt(stickClip.height * stickClip.height);
			stickLen = stickClip.height;
			
			resetCenter();  // reset what is considered center position
			active = false; // joystick starts at rest
			
			// set in center (start) position.  We use hsExactX and hsExactY because
			// hotspotClip is limited in resolution to screen position. This messes up exact
			// setting when the user sets the position programmatically.  Therefore,
			// we keep track of the exact location for the hot spot and use that in
			// calculations in place of the hotspotClip movie clip spot.
			hsExactX = hsExactY = 0;
			zeroCall = false;
			setStick();
			
			joystickContainer.x = width / 2;
			joystickContainer.y = height / 2;
			
			joystickContainer.scaleX = joystickContainer.scaleY = width / JOYSTICK_WIDTH;
			
			// Last line must call superclass method
			super.draw();
		}
		
		protected function changeBase (n:String) : void {
			var baseSkinClass:Class = getDefinitionByName(n) as Class;
			var oldBase:Sprite = baseClip;
			
			if (oldBase != null) {
				joystickContainer.removeChild(oldBase);
			}
			
			baseClip = new baseSkinClass() as Sprite;
			
			joystickContainer.addChildAt(baseClip, 0);
			
			
			_baseClassName = n;
		}
		
		protected function changeStick (n:String) : void {
			var stickSkinClass:Class = getDefinitionByName(n) as Class;
			var oldStick:Sprite = stickClip;
		
			stickClip = new stickSkinClass() as Sprite;
			
			if (oldStick != null) {
				joystickContainer.removeChild(oldStick);
			}
			joystickContainer.addChildAt(stickClip, 1);
			
			_stickClassName = n;
		}
		
		protected function changeHotspot (n:String) : void {
			var hsSkinClass:Class = getDefinitionByName(n) as Class;
			var oldHS:Sprite = hotspotClip;
			
			hotspotClip = new hsSkinClass() as Sprite;

			if (oldHS != null) {
				joystickContainer.removeChild(oldHS);
				oldHS.removeEventListener(MouseEvent.MOUSE_DOWN, moveHS);
			}
			
			hotspotClip.addEventListener(MouseEvent.MOUSE_DOWN, moveHS);
			
			joystickContainer.addChildAt(hotspotClip, 2);
	
			hotspotClip.buttonMode = hotspotClip.useHandCursor = showHand;
			_hotspotClassName = n;
		}
		
		
		
		/* ***************************************************
		 * Exposed Methods
		 * *************************************************** */
		
		/**
		Returns the vector position of the joystick, in an object with x and y properties.  Note that
		the object is reused for subsequent calls to <code>getVec()</code>, so you should copy the
		values if you need to store them for any reason.
		@method getVec
		*/
		public function getVec () : Point {
			ptObj.x = (hsExactX / limit) * _maxVal;
			ptObj.y = (-hsExactY / limit) * _maxVal;
			
			return ptObj;
		}
		
		/**
		Sets the joystick to the given vector.  Must be preceded by call to moveHS if joystick is
		being moved programmatically.
		@method setVec
		@param x x-coordinate position (<code>-maxVal</code> to <code>maxVal</code>)
		@param y y-coordinate position (<code>-maxVal</code> to <code>maxVal</code>)
		*/
		public function setVec (xp:Number, yp:Number) : void {
			setXY(( xp / _maxVal ) * limit, ( -yp / _maxVal ) * limit);
		}
		
		
		// Resets what is considered the zero (center) point
		protected function resetCenter () {
			// set the center allowance in pixels (less than this amt is considered 0)
			centerPx = (_centerEPS / _maxVal) * limit;
		}

		
		/**
		Initialize moving of hot spot.  Developers use this only when moving the joystick programmatically.
		Use <code>setVec()</code> to set the position, after calling <code>moveHS()</code>, then call
		<code>stopMoveHS</code> when you are finished moving the joystick (make sure the pass the argument
		as <code>true</code>).
		@method moveHS
		@param e The MouseEvent passed in when the joystick user clicks on the joystick to start moving it.
		@param useMouse Set this to false if you are moving the joystick programmatically.
		@param quiet Set this to true not to generate an onJStart event
		*/
		public function moveHS (e:MouseEvent, useMouse:Boolean = true, q:Boolean = false) : void {
		
			stage.addEventListener(MouseEvent.MOUSE_UP, stopMoveHS);
		
			if (!allowEvents) {
				dispatchEvent(new EventWithData(evtDisabled, false, false, null));
				return;
			}
			
			if (useMouse) {
				stage.addEventListener(MouseEvent.MOUSE_MOVE, trackHS);
			}
			
			if (!q) {
				// Generate start joystick move event
				dispatchEvent(new EventWithData(evtJStart, false, false, null));
			}
			
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, return2Center);
			}
			
			if (_genPulseEvent) {
				clearInterval(_pulseID);
				_pulseID = setInterval(genPulse, _pulseFreq);
			}
				
			active = true;
		}
		
		/**
		Stop tracking movement of the joystick.  The arg noMouse is a hook to allow the joystick to be
		controlled programmatically.
		@method stopMoveHS
		@param e The event passed in when the joystick user has released the joystick (hotspot).
		@param useMouse Set this to false if you are moving the joystick programmatically.
		@param quiet Set this to true to not generate an onJReleased event
		*/
		public function stopMoveHS(e:MouseEvent, useMouse:Boolean = true, quiet:Boolean = false) : void {
		
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopMoveHS);
			if (stage.hasEventListener(MouseEvent.MOUSE_MOVE)) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackHS);
			}

			if (!allowEvents) {
				return;
			}
					
			// Return to center unless joystick supposed to stick
			if (kSticky < 1) {
				addEventListener(Event.ENTER_FRAME, return2Center);
			}
				
			if (!quiet) {
				computeJPosition();
				eventObj.type = evtJReleased;
				eventObj.val = ptObj; 
				dispatchEvent(new EventWithData(evtJReleased, false, false, eventObj));
			}
			
		}
		
		protected function chgPulseFreq (pf:Number) : void {
			_pulseFreq = pf;

			if (active) {
				clearInterval(_pulseID);
				if (_genPulseEvent) {
					_pulseID = setInterval(genPulse, _pulseFreq);
				}
			}
		}
		
		/**
		 * Removes internal listeners and memory associated with the component.
		 */
		public function destroy () : void {
			clearInterval(_pulseID);
			hotspotClip.removeEventListener(MouseEvent.MOUSE_DOWN, moveHS);
			if (stage.hasEventListener(MouseEvent.MOUSE_MOVE)) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackHS);
			}
			if (stage.hasEventListener(MouseEvent.MOUSE_UP)) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopMoveHS);
			}
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, return2Center);
			}
			removeEventListener(Event.REMOVED_FROM_STAGE, catchNoStagePtr);
		}
		 
		 
		/* ***************************************************
		 * protected/Protected Methods
		 * *************************************************** */
		 
		// Using the position of the hot spot, rotate the stick and scale it based on distance
		// from center.  We compute the rotation angle using the dot product of the upright
		// vector (in screen coords, (0, -1)) and the mouse position.
		protected function setStick () : void {
			var hsx = hotspotClip.x, hsy = hotspotClip.y, sum, angle, vdot;
				sum = Math.sqrt(hsx * hsx + hsy * hsy);
				
			if (sum != 0) {
				hsy /= sum;
				// dot product gives us the angle between vectors (upright and mouse position)
				// vdot = hsx*nx + hsy*ny; but we can simplify because nx = 0 and ny = -1.
				vdot = -hsy;
				// convert from radians to degrees
				angle = 57.2957795130823 * Math.acos(vdot);
				if (hsx < 0)
					angle *= -1;
				
				stickClip.rotation = angle;
			}
			stickClip.scaleY = (sum / stickLen);
		}
		

		// Routine that brings the joystick back to the center (0) position based on the stickiness of the joystick
		protected function return2Center(e:Event) : void {
			var xp:Number = hotspotClip.x, yp:Number = hotspotClip.y, coeff, len;
		
			len = Math.sqrt(xp*xp + yp*yp);
			if (len < centerPx) {
				coeff = 0;
			} else {
				coeff = kSticky;
			}
		
			hotspotClip.x = hsExactX = coeff * xp;
			hotspotClip.y = hsExactY = coeff * yp;
			setStick();
			if (coeff == 0) {
				active = false;
	
				// When joystick reaches center, stop reporting values
				removeEventListener(Event.ENTER_FRAME, return2Center);
				
				genPulse(true); // Generate a final pulse			
				
				clearInterval(_pulseID);
				eventObj.type = evtJReturned;
				eventObj.val = undefined;
				dispatchEvent(new EventWithData(evtJReturned, false, false, eventObj));
			
			} else {
				genPulse(true);
			}
		}
		
		
		/**
		 * Internal function called while the user is moving the joystick hot spot.
		 */
		protected function trackHS (e:MouseEvent) : void {
			setXY(joystickContainer.mouseX, joystickContainer.mouseY);
			genPulse(true);
		}
		
		/**
		 * Internal function to set the joystick in the direction of the vector passed in.
		 * The XY do not necessarily have to be within the range of the joystick -- it
		 * will limit its length automatically.
		 */
		protected function setXY (xp:Number, yp:Number) : void {
			var vLen:Number, vX:Number, vY:Number, vL:Number;
			
			// we compute the vector to the mouse.  We set the hotspot to the minimum of
			// that position or the joystick boundary given by distance 'limit'.
			vLen = Math.sqrt(xp*xp + yp*yp);
			
			// check if joystick is close enough to 0
			if (vLen < centerPx) {
				vL = vX = vY = 0;
			} else {
				vX = xp / vLen;
				vY = yp / vLen;
				vL = Math.min(vLen, limit);
			}
	
			hotspotClip.x = hsExactX = vL * vX;
			hotspotClip.y = hsExactY = vL * vY;
			
			setStick();
		}
		
		protected function genPulse (chg:Boolean = false) : void {
			// Tell any listeners about the change, but don't repeat once hits (0, 0)
			computeJPosition();
			
			if (zeroCall || ptObj.x != 0 || ptObj.y != 0) {
				eventObj.val = ptObj;
				if (chg) {
					eventObj.type = evtJChg;
					dispatchEvent(new EventWithData(evtJChg, false, false, eventObj));  
				} else {
					eventObj.type = evtJPulse;
					dispatchEvent(new EventWithData(evtJPulse, false, false, eventObj)); 
				}
		
				// zeroCall says whether joystick is at 0
				zeroCall = (ptObj.x != 0 || ptObj.y != 0);
			}
		}
		
		// Compute the joystick position
		protected function computeJPosition () {
			var xp = hsExactX, yp = hsExactY;
		
			ptObj.x = _maxVal * (xp / limit);
			ptObj.y = - _maxVal * (yp / limit);
		
			if (forceInt) {
				ptObj.x = Math.round(ptObj.x);
				ptObj.y = Math.round(ptObj.y);
			}
		}
		
		/**
		 * If we're removed from the stage after a press event but before getting a release event, make sure we remove any stage listeners.
		 */
		protected function catchNoStagePtr (e:Event) : void {
			if (stage != null && stage.hasEventListener( MouseEvent.MOUSE_UP ) ) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopMoveHS);
			}
			if (stage != null && stage.hasEventListener ( MouseEvent.MOUSE_MOVE ) ) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackHS);
			}
		}
	}
}