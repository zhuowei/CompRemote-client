package {
import flash.display.*;
import flash.desktop.*;
import flash.net.*;
import flash.events.*;
import flash.ui.*;
import flash.utils.*;
import qnx.dialog.*;
import qnx.display.*;
[SWF(height="1024", width="600", frameRate="30", backgroundColor="#ffffff")]
public class CompRemote extends Sprite{
	public static const SCROLL_INTERVAL:int = 20;
	public static const CLICK_DELAY:int = 100;
	private static const TAP_TOLERENCE:Number = 3;
	public var sock:Socket;
	public var session:RemoteSession;
	public var passwordHash:String;
	public var touchPad:Sprite;
	public var leftButton:Sprite;
	public var rightButton:Sprite;
	public var ipAddress:String;
	public var mouseIsDown:Boolean;
	private var initialTouchPadX:Number;
	private var initialTouchPadY:Number;
	private var leftDown:Boolean=false;
	private var rightDown:Boolean=false; 
	public var lastX:Number;
	public var lastY:Number;
	public var lastScrollY:Number;
	private var curScrollAmount:Number;
	public var scrollArea:Sprite;

	public var serversScreen:ServersScreen;
	
	public function CompRemote(){
		init();
	}
	private function init():void{
		stage.addEventListener("orientationChange", function(e:Event):void{
			if(touchPad!=null){
				resizeUI();
			}
			if (serversScreen != null) {
				serversScreen.resizeUi();
			}
		});
		stage.addEventListener("resize", function(e:Event):void{
			if(touchPad!=null){
				resizeUI();
			}
			if (serversScreen != null) {
				serversScreen.resizeUi();
			}
		});
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode=StageScaleMode.NO_SCALE;
		//popUpDialog();
		showServersScreen();
	}
	private function popUpDialog():void{
		var login:LoginDialog=new LoginDialog();
		login.title="CompRemote 2.2 Lite";
		login.message="Please enter the IP address and the password of the computer that you would like to control.";
		//login.message="w" + stage.stageWidth + "h:"+ stage.stageHeight;
		login.usernameLabel="IP address:";
		login.passwordLabel="Password: ";
		login.addButton("OK");
		login.addEventListener(Event.SELECT, loginDialogHandler);
		login.show(IowWindow.getAirWindow().group);
		function loginDialogHandler(e:Event):void{
			ipAddress=login.username;
			passwordHash=hashPassword(login.password);
			connect();
		}
	}

	private function showServersScreen():void {
		serversScreen = new ServersScreen();
		//serversScreen.width = stage.stageWidth;
		//serversScreen.height = stage.stageHeight;
		serversScreen.x = 0;
		serversScreen.y = 0;
		addChild(serversScreen);
		serversScreen.addEventListener("serverSelect", serverSelectHandler);
		serversScreen.addEventListener("quickConnectClick", quickConnectClickHandler);
		serversScreen.resizeUi();
	}

	private function serverSelectHandler(e:Event):void {
		hideServersScreen();
		ipAddress = serversScreen.selectedIpAddress;
		passwordHash = serversScreen.selectedPasswordHash;
		connect();
	}

	private function hideServersScreen():void {
		try {
			removeChild(serversScreen);
		} catch (e:Error) {
		}
	}

	private function quickConnectClickHandler(e:Event):void {
		hideServersScreen();
		popUpDialog();
	}

	private function connect():void{
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		sock=new Socket();
		sock.addEventListener(Event.CONNECT, connectHandler);
		sock.addEventListener(Event.CLOSE, disconnectHandler);
		sock.addEventListener("ioError", function(e:Event):void{
				connectErrorPopup(e.toString());
			});
		try{
			sock.connect(ipAddress, 24125); // should be an empty port
		}
		catch(e:Error){
			connectErrorPopup(e.toString());
		}
			
	}
	private function connectHandler(e:Event):void{
		trace("connect");
		session=new RemoteSession(sock);
		//session.auth(SHA1.encrypt(SHA1.encrypt(password)+"*&#~")); //This looks stupid and insecure because it is
		session.auth(passwordHash);
		connected();
	}
	private function disconnectHandler(e:Event):void{
		trace("disconnect!");
		var notice:AlertDialog=new AlertDialog();
		notice.title="Disconnected";
		notice.message="You have been disconnected from the remote computer.";
		notice.addButton("OK");
		notice.addEventListener("select", function(e:Event):void{
			NativeApplication.nativeApplication.exit(0);
		});
		notice.show(IowWindow.getAirWindow().group);
	}
	private function connectErrorPopup(msg:String):void{
		var notice:AlertDialog=new AlertDialog();
		notice.title="Connection failure";
		notice.message="CompRemote was unable to connect to the remote IP address.\n" + msg;
		notice.addButton("OK");
		notice.addEventListener("select", function(e:Event):void{
			NativeApplication.nativeApplication.exit(0);
		});
		notice.show(IowWindow.getAirWindow().group);
	}
	private function connected():void{
		buildUI();
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
	}
	private function buildUI():void{
		touchPad=new Sprite();
		scrollArea=new Sprite();
		leftButton=new Sprite();
		rightButton=new Sprite();
		touchPad.addEventListener(TouchEvent.TOUCH_MOVE, touchPadMove);
		touchPad.addEventListener(TouchEvent.TOUCH_BEGIN, touchPadDown);
		touchPad.addEventListener(TouchEvent.TOUCH_END, touchPadUp);
		touchPad.addEventListener(TouchEvent.TOUCH_OUT, touchPadUp);
		scrollArea.addEventListener(TouchEvent.TOUCH_MOVE, scrollAreaMove);
		scrollArea.addEventListener(TouchEvent.TOUCH_BEGIN, scrollAreaDown);
		leftButton.addEventListener(TouchEvent.TOUCH_BEGIN, function(e:TouchEvent):void{
			leftDown=true;
			session.mouseDown(1);
		});
		leftButton.addEventListener(TouchEvent.TOUCH_END, function(e:TouchEvent):void{
			if(leftDown){
				session.mouseUp(1);
				leftDown=false;
			}
		});
		leftButton.addEventListener(TouchEvent.TOUCH_OUT, function(e:TouchEvent):void{
			if(leftDown){
				session.mouseUp(1);
				leftDown=false;
			}
		});
		rightButton.addEventListener(TouchEvent.TOUCH_BEGIN, function(e:TouchEvent):void{
			rightDown=true;
			session.mouseDown(3);
		});
		rightButton.addEventListener(TouchEvent.TOUCH_END, function(e:TouchEvent):void{
			if(rightDown){
				session.mouseUp(3);
				rightDown=false;
			}
		});
		rightButton.addEventListener(TouchEvent.TOUCH_OUT, function(e:TouchEvent):void{
			if(rightDown){
				session.mouseUp(3);
				rightDown=false;
			}
		});
		resizeUI();
		addChild(touchPad);
		addChild(scrollArea);
		addChild(leftButton);
		addChild(rightButton);
	}
	private function resizeUI():void{
		var buttonHeight:Number=stage.stageHeight*0.2;
		var buttonWidth:Number=stage.stageWidth/2;
		var padHeight:Number=stage.stageHeight-buttonHeight;
		var padWidth:Number=stage.stageWidth;
		var showScrollArea:Boolean=false;
		var scrollAreaHeight:Number=padHeight;
		var scrollAreaWidth:Number=0;
		if(padHeight<padWidth){ //landscape){
			showScrollArea=true;
			scrollAreaWidth=padWidth*0.1;
			padWidth=padWidth-scrollAreaWidth;
		}
		touchPad.graphics.clear();
		touchPad.graphics.beginFill(0xbbbbbb);
		touchPad.graphics.drawRect(0,0,padWidth, padHeight);
		touchPad.graphics.endFill();
		touchPad.x=0;
		touchPad.y=0;
		leftButton.graphics.clear();
		leftButton.graphics.beginFill(0x888888);
		leftButton.graphics.drawRect(0,0,buttonWidth, buttonHeight);
		leftButton.graphics.endFill();
		leftButton.x=0;
		leftButton.y=padHeight;
		rightButton.graphics.clear();
		rightButton.graphics.beginFill(0x666666);
		rightButton.graphics.drawRect(0,0,buttonWidth, buttonHeight);
		rightButton.graphics.endFill();
		rightButton.x=buttonWidth;
		rightButton.y=padHeight;
		scrollArea.graphics.clear();
		if(showScrollArea){
			scrollArea.visible=true;
			scrollArea.x=touchPad.x+touchPad.width;
			scrollArea.y=0;
			scrollArea.graphics.beginFill(0x999999);
			scrollArea.graphics.drawRect(0,0,scrollAreaWidth, scrollAreaHeight);
			scrollArea.graphics.endFill();
			scrollArea.graphics.lineStyle(5, 0xbbbbbb);
			for(var i:int=0;i<scrollAreaHeight;i+=SCROLL_INTERVAL){
				scrollArea.graphics.moveTo(0, i);
				scrollArea.graphics.lineTo(scrollAreaWidth, i);
			}
		}
		else{
			scrollArea.visible=false;
		}
	}
	private function touchPadDown(e:TouchEvent):void{
		mouseIsDown=true;
		initialTouchPadX = e.localX;
		initialTouchPadY = e.localY;
		lastX=e.localX;
		lastY=e.localY;
	}
	private function touchPadUp(e:TouchEvent):void{
		mouseIsDown=false;
		var deltaX:Number = Math.abs(e.localX - initialTouchPadX);
		var deltaY:Number = Math.abs(e.localY - initialTouchPadY);
		if(deltaX <= TAP_TOLERENCE && deltaY <= TAP_TOLERENCE && !leftDown){
			sendClick();
		}
	}
	private function touchPadMove(e:TouchEvent):void{
		if(!mouseIsDown){
			return;
		}
		var deltaX:Number=e.localX-lastX;
		var deltaY:Number=e.localY-lastY;
		trace(deltaX + " : " + deltaY);
		session.mouseMove(int(deltaX*3+0.5), int(deltaY*3+0.5));
		lastX=e.localX;
		lastY=e.localY;
	}
	private function scrollAreaDown(e:TouchEvent):void{
		lastScrollY=e.localY;
		curScrollAmount = 0;
	}
	private function scrollAreaMove(e:TouchEvent):void{
		curScrollAmount += e.localY - lastScrollY;
		if(Math.abs(curScrollAmount) >= SCROLL_INTERVAL){
			var direction:int=(e.localY-lastScrollY>0? 1: -1);
			session.mouseWheel(direction);
			curScrollAmount = curScrollAmount % SCROLL_INTERVAL;
		}
		lastScrollY=e.localY;
	}
	public function sendClick():void{
		session.mouseDown(1);
		setTimeout(releaseClick, CLICK_DELAY);
	}
	private function releaseClick():void{
		session.mouseUp(1);
	}

	private function keyDownHandler(e:KeyboardEvent):void{
		//Keycodes used in Flash and keycodes used by Java are different.
		//I'm not that good at converting the two. This is why some symbols do not show up.
		if (hasShift(e.charCode)) session.keyPress(16); //Hack for capital letters
		session.keyPress(getKeyCode(e.keyCode, e.charCode));
	}

	private function keyUpHandler(e:KeyboardEvent):void{
		session.keyRelease(getKeyCode(e.keyCode, e.charCode));
		if (hasShift(e.charCode)) session.keyRelease(16); //Hack for capital letters
	}
	private function hasShift(code:int):Boolean{
		return String.fromCharCode(code).search(/[\?~!@#$%^&*():A-Z]/) != -1;
	}
	private function getKeyCode(code:int, charcode:int):int {
		/*if ((code >= 65 && code <= 90) || (code >= 96 && code <= 122) || (code >= 48 && code <= 57)) {
			return code;
		}*/
		if (code == 13) { //enter
			return 10;
		}
		if (charcode == 58) { // double quote
			return 152;
		}
		if (charcode == 63) {
			return 47;
		}
		if(String.fromCharCode(charcode).search(/[-,.\/\\:_;=+\[\]<>{}]/) != -1) {
			return charcode;
		}
		return code;
	}

	public static function hashPassword(password:String):String {
		return SHA1.encrypt(SHA1.encrypt(password)+"*&#~");
	}
}
}
