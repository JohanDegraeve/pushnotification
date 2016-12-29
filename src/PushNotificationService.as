package
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class PushNotificationService
	{
		public function PushNotificationService()
		{
		}
		
		//import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
		import com.hurlant.util.Base64;
		import com.hurlant.util.Hex;
		
		
		import quickbloxsecrets.QuickBloxSecrets;
		private static const QUICKBLOX_DOMAIN:String = "https://api.quickblox.com";
		private static const QUICKBLOX_REST_API_VERSION:String = "0.1.0";
		private static var QB_Token:String = "";
		public static var ALPHA_CHAR_CODES:Array = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
		
		public static function createSessionQuickBlox():void {
			//var udid:String = Application.service.device.uniqueId("vendor", true);
			var nonce:String = createNonce(10);
			var timeStamp:String = (new Date()).valueOf().toString().substr(0, 10);
			var toSign:String = "application_id=" + QuickBloxSecrets.ApplicationId 
				+ "&auth_key=" + QuickBloxSecrets.AuthorizationKey
				+ "&nonce=" + nonce
				+ "&timestamp=" + timeStamp;
			
			var key:ByteArray = Hex.toArray(Hex.fromString(QuickBloxSecrets.AuthorizationSecret));
			var data:ByteArray = Hex.toArray(Hex.fromString(toSign));
			var signature:String = BackgroundFetch.generateHMAC_SHA1(QuickBloxSecrets.AuthorizationSecret, toSign);
			
			var postBody:String = 
				'{"application_id": "' + QuickBloxSecrets.ApplicationId + 
				'", "auth_key": "' + QuickBloxSecrets.AuthorizationKey + 
				'", "timestamp": "' + timeStamp + 
				'", "nonce": "' + nonce + 
				'", "signature": "' + signature +
				'"}';
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(QUICKBLOX_DOMAIN + "/session.json");
			request.contentType = "application/json";
			request.method = URLRequestMethod.POST;					
			request.data = postBody;
			request.requestHeaders.push(new URLRequestHeader("QuickBlox-REST-API-Version", QUICKBLOX_REST_API_VERSION));
			loader.addEventListener(Event.COMPLETE, createBloxSessionSuccess);
			loader.addEventListener(IOErrorEvent.IO_ERROR, createBloxSessionFailure);
			loader.load(request);
		}
		
		private static function createBloxSessionFailure(event:IOErrorEvent):void {
			trace("PushNotificationService.as createBloxSessionFailure " + (event.currentTarget.data ? event.currentTarget.data:""));
		}
		
		private static function createBloxSessionSuccess(event:Event):void {
			trace("PushNotificationService.as createBloxSessionSuccess");
			var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			QB_Token = eventAsJSONObject.session.token;
			userSignInQuickBlox();
		}
		
		private static function userSignInQuickBlox():void {
			var postBody:String = '{"login": "' + QuickBloxSecrets.MasterQuickBloxLogin + '", "password": "' + QuickBloxSecrets.Masterpw + '"}';
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(QUICKBLOX_DOMAIN + "/login.json");
			request.method = URLRequestMethod.POST;					
			request.data = postBody;
			request.contentType = "application/json";
			request.requestHeaders.push(new URLRequestHeader("QuickBlox-REST-API-Version", QUICKBLOX_REST_API_VERSION));
			request.requestHeaders.push(new URLRequestHeader("QB-Token", QB_Token));
			loader.addEventListener(Event.COMPLETE, signInSuccess);
			loader.addEventListener(IOErrorEvent.IO_ERROR, signInFailure);
			loader.load(request);
		}
		
		private static function signInSuccess(event:Event):void {
			trace("PushNotificationService.as signInSuccess");
			var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			
			sendPushNotification();
			
		}
		
		private static function sendPushNotification():void {
			var payload:String = "{" +
				"aps =     {" + 
				'"content-available" = 1;' + 
				'"alert" = "";' +
				'"priority" = 10;' +
				'};' +
				'}';
			payload = Base64.encode(payload);
			
			var postBody:String = '{"event": {"notification_type": "push", "environment": "production", ' +
				'"message": "payload=' + payload + '", "push_type": "apns"}}';
			
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(QUICKBLOX_DOMAIN + "/events.json");
			request.contentType = "application/json";
			request.method = URLRequestMethod.POST;					
			request.data = postBody;
			request.requestHeaders.push(new URLRequestHeader("QuickBlox-REST-API-Version", QUICKBLOX_REST_API_VERSION));
			request.requestHeaders.push(new URLRequestHeader("QB-Token", QB_Token));
			loader.addEventListener(Event.COMPLETE, pushNotificationSentSuccess);
			loader.addEventListener(IOErrorEvent.IO_ERROR, pushNotificationSentFailure);
			loader.load(request);
		}
		
		private static function pushNotificationSentSuccess(event:Event):void {
			trace("PushNotificationService.as pushNotificationSentSuccess");
		}
		
		private static function pushNotificationSentFailure(event:IOErrorEvent):void {
			trace("PushNotificationService.as pushNotificationSentFailure" + (event.currentTarget.data ? event.currentTarget.data:""));
		}
		
		private static function signInFailure(event:IOErrorEvent):void {
			trace("PushNotificationService.as signInFailure " + (event.currentTarget.data ? event.currentTarget.data:""));
		}
		
		public static function createNonce(length:int):String {
			var nonce:Array = new Array(length);
			for (var i:int = 0; i < length; i++) {
				nonce[i] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  10)];
			}
			var returnValue:String = "";
			for (i = 0; i < nonce.length; i++)
				returnValue += nonce[i];
			return returnValue;
		}
		

	}
}