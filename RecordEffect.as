package com.peach.uofs.components.reading
{
	import com.peach.uofs.server.Server;
	
	import flash.events.Event;
	import flash.media.Microphone;
	import flash.utils.ByteArray;
	
	import mx.effects.Effect;
	import mx.effects.IEffectInstance;
	import mx.events.EffectEvent;
	
	public class RecordEffect extends Effect
	{
		/**
		 * constants used for setting behavior
		 */
		public static const RECORD_MODE:String = "record_mode";
		public static const PLAY_MODE:String = "play_mode";
		
		private var soundBytes:ByteArray = new ByteArray();
		
		/**
		 * url to load/save sound data
		 */
		public function get url():String
		{
			return _url;
		}
		
		public function set url(value:String):void
		{
			_url = value;
			Server.downloadRecording(value, function(e:Event):void{
				trace("recording does not exist yet");				
			}, pushLoadedData);
		}
		
		/**
		 * private copy of setter/getter
		 */
		private var _url:String = null;
		
		
		/**
		 * set mode to either RecordEffect.RECORD_MODE or RecordEffect.PLAY_MODE
		 */
		public function get mode():String 
		{
			return _currentMode;
		}
		
		public function set mode(value:String):void 
		{
			trace("changing record effect mode to "+value);
			if(value == RECORD_MODE || value == PLAY_MODE){
				_currentMode = value;
			}
		}
		
		private var _currentMode:String = RECORD_MODE;
		
		/**
		 * constructor for the record effect
		 */
		public function RecordEffect(target:Object = null)
		{
			super(target);
			instanceClass= RecordEffectInstance;
			this.addEventListener(EffectEvent.EFFECT_END, trySave);
		}
				
		override public function getAffectedProperties():Array {
			return [];
		}
		
		override protected function initInstance(inst:IEffectInstance):void {
			trace("Creating effec instance "+_url);
			super.initInstance(inst);
			var recEffecInst:RecordEffectInstance = inst as RecordEffectInstance;
			recEffecInst.sampleBuffer = soundBytes;
			if(_currentMode == PLAY_MODE){
				recEffecInst.playMode = recEffecInst.playSound;	
			}else{
				recEffecInst.playMode = recEffecInst.record;
			}
		}
		
		/**
		 * saves data from server to byte array for sound playing
		 */
		private function pushLoadedData(data:ByteArray):void
		{
			trace("got recorded sound data back from server");
			soundBytes.writeBytes(data, 0, data.length);
			this.dispatchEvent(new Event(Event.COMPLETE));	
		}
		
		/**
		 * when event fires, try to upload sound data to server
		 */
		private function trySave(event:* = null):void
		{
			if((url != "") && (_currentMode == RECORD_MODE) && (soundBytes.length > 0)){
				trace("buffer "+_url+" size "+soundBytes.length);
				Server.uploadRecording(url, soundBytes, function(err:Event):void{
					trace("upload failed");
				}, 
				function():void{
					trace("upload done");
				});
			}else{
				trace("skipping upload as nothing has changed");
			}
		}
	}
}