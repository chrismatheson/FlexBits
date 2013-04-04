package com.peach.uofs.components.reading
{
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.effects.EffectInstance;
	import mx.effects.IEffectInstance;
	
	public class RecordEffectInstance extends EffectInstance implements IEffectInstance
	{
		public function RecordEffectInstance(target:Object)
		{
			trace("Effect Constructor");
			super(target);
		}
		
		/**
		 * this is the function called as part of the animation sequence
		 */
		public var playMode:Function = record;
		
		/**
		 * play - replace this with either playSound() or record() function at run time
		 */
		override public function play():void {
			trace("Playing Effect instance ");
			playMode();
		}
		
		private function timeoutCleanup(event:TimerEvent):void{
			end();
		}
		
		override public function get duration():Number
		{
			return super.duration;
		}
		
		/**
		 * internal timer that should be set to duration variable
		 */
		private var _timeout:Timer = null;
		
		override public function set duration(value:Number):void
		{
			_timeout = new Timer(value, 1);
			super.duration = value;
		}
		
		// Override end() method class to stop the MP3.
		override public function end():void {
			trace("Recording effect finished");
			_timeout.reset();
			super.end();
		}
		
		
		/**
		 * sound object is local to the Recording. becuase you need the rawRecData to play it.
		 */
		private var mic:Microphone;
		
		/**
		 * The raw data that will be stored on the server
		 */
		public var sampleBuffer:ByteArray = new ByteArray();
		
		/**
		 * Records sound from the mic and emits a ``UOSPageEvent.FINISHEDACTIVITY`` when 3 secconds is recorded
		 * emits a ``UOSPageEvent.STARTEDACTIVITY`` when function is called
		 */
		public function record(event:* = null):void
		{
			sampleBuffer.clear();
			sampleBuffer.length = 0;
			mic = Microphone.getMicrophone();
			mic.setUseEchoSuppression(true); 
			mic.setSilenceLevel(0);
			mic.rate = 44;
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, this.pushSampleData);
			
			_timeout.addEventListener(TimerEvent.TIMER_COMPLETE, recordFinishCleanup);
			_timeout.start();
			
			super.play();
		}
		
		private function recordFinishCleanup(event:TimerEvent):void{
			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, pushSampleData);
			end();
		}
		
		/**
		 * this function listens for sampleData while recording and pushes it onto the rawRecData buffer
		 */
		private function pushSampleData(e:SampleDataEvent):void
		{
			sampleBuffer.length += e.data.length;
			sampleBuffer.writeBytes(e.data);
		}
				
		public function playSound():void
		{
			trace("Playing recording");
			sampleBuffer.position = 0;
			if(sampleBuffer.bytesAvailable == 0){
				trace("nothing to play");
				end();
				return;	
			}
			var sound:Sound = new Sound();
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, generateSampleData);
			var soundChan:SoundChannel = sound.play();
			soundChan.addEventListener(Event.SOUND_COMPLETE, function(event:Event):void{
				end();
			});
			super.play();
		}
		
		/**
		 * used for playing back sound from buffer
		 */
		private function generateSampleData(e:SampleDataEvent):void
		{
			if (!sampleBuffer.bytesAvailable > 0){
				return;    // stop of no sound recorded
			}
			
			var length:int = 8192;
			for (var i:int = 0; i < length; i++) {
				var sample:Number = 0;
				if (sampleBuffer.bytesAvailable > 0) sample = sampleBuffer.readFloat();
				e.data.writeFloat(sample);   // channel 1
				e.data.writeFloat(sample);   // channel 2
			}
		}
	}
}