package {
import flash.display.*;
import flash.desktop.*;
import flash.net.*;
import flash.events.*;
import flash.ui.*;
import flash.utils.*;
import qnx.dialog.*;
import qnx.display.*;
import qnx.fuse.ui.core.*;
import qnx.fuse.ui.buttons.*;
import qnx.fuse.ui.events.*;
import qnx.fuse.ui.listClasses.*;
import qnx.ui.data.*;

public class ServersScreen extends Sprite {

	public var savedServers:Array;

	public var serverListProvider:DataProvider;

	public var quickConnectButton:LabelButton;
	public var addServerButton:LabelButton;
	public var deleteModeButton:LabelButton;

	public var serverList:List;

	public var selectedIpAddress:String;
	public var selectedPasswordHash:String;

	public var serverSelected:ServerInfo;

	public function ServersScreen() {
		try {
			registerClassAlias("net.zhuoweizhang.compremote.ServerInfo", ServerInfo);
			loadSavedServers();
		} catch (e:Error) {
			logError(e.toString());
		}
		initUi();
	}

	private function loadSavedServers():void {
		var serverSharedObject:SharedObject = SharedObject.getLocal("compRemoteSavedServers");
		var arr:Array = serverSharedObject.data.savedServers;
		if (!arr || arr == null) {
			savedServers = [];
		} else {
			savedServers = arr;
		}
	}

	private function saveSavedServers():void {
		try {
			var serverSharedObject:SharedObject = SharedObject.getLocal("compRemoteSavedServers");
			serverSharedObject.data.savedServers = savedServers;
			serverSharedObject.flush();
		} catch (e:Error) {
			logError(e.toString());
		}
	}

	private function initUi():void {
		quickConnectButton = new LabelButton();
		quickConnectButton.label = "Quick Connect";
		addServerButton = new LabelButton();
		addServerButton.label = "Add computer";
		deleteModeButton = new LabelButton();
		deleteModeButton.label = "Delete computer";
		deleteModeButton.toggle = true;
		serverListProvider = new DataProvider(savedServers);
		serverList = new List();
		serverList.dataProvider = serverListProvider;
		addChild(serverList);
		addChild(quickConnectButton);
		addChild(addServerButton);
		addChild(deleteModeButton);
		quickConnectButton.addEventListener("click", showQuickConnectDialogHandler);
		addServerButton.addEventListener("click", addServerButtonClickHandler);
		serverList.addEventListener("listItemClicked", listItemClickedHandler);
		//resizeUi();
	}

	public function resizeUi():void {
		var buttonHeight:Number = 40;
		serverList.x = 10;
		serverList.y = 10;
		serverList.width = stage.stageWidth - 20;
		serverList.height = stage.stageHeight - 30 - buttonHeight;
		quickConnectButton.x = 10;
		quickConnectButton.y = serverList.y + serverList.height + 10;
		quickConnectButton.width = 180;
		addServerButton.x = quickConnectButton.x + quickConnectButton.width + 5;
		addServerButton.y = quickConnectButton.y;
		addServerButton.width = 180;
		deleteModeButton.x = addServerButton.x + addServerButton.width + 5;
		deleteModeButton.y = quickConnectButton.y;
		deleteModeButton.width = 180;
	}

	private function showQuickConnectDialogHandler(e:Event):void {
		dispatchEvent(new Event("quickConnectClick"));
	}

	private function addServerButtonClickHandler(e:Event):void {
		showAddServerPanel();
	}

	private function showAddServerPanel():void {
		/*var server:ServerInfo = new ServerInfo();
		server.name = "Lame server";
		server.ip = "192.168.1.106";
		serverListProvider.addItem(server);
		saveSavedServers();*/
		var ipPrompt:PromptDialog=new PromptDialog();
		ipPrompt.title="Enter IP address";
		ipPrompt.message="Please enter the IP address of the computer that you would like to connect to.";
		ipPrompt.prompt = "IP address:"
		ipPrompt.addButton("Continue");
		ipPrompt.addEventListener(Event.SELECT, ipPromptDialogHandler);
		ipPrompt.show(IowWindow.getAirWindow().group);
		function ipPromptDialogHandler(e:Event):void{
			var namePrompt:PromptDialog=new PromptDialog();
			namePrompt.title="Enter name";
			namePrompt.message="Please enter a name for the computer with IP address " + ipPrompt.text + ".";
			namePrompt.prompt = "Name:"
			namePrompt.addButton("Save");
			namePrompt.addEventListener(Event.SELECT, namePromptDialogHandler);
			namePrompt.show(IowWindow.getAirWindow().group);
			function namePromptDialogHandler(e:Event):void {
				var server:ServerInfo = new ServerInfo();
				server.name = namePrompt.text;
				server.ip = ipPrompt.text;
				serverListProvider.addItem(server);
				saveSavedServers();
			}
		}
	}

	private function listItemClickedHandler(e:ListEvent):void {
		if (deleteModeButton.selected) {
			serverListProvider.removeItemAt(e.index);
			saveSavedServers();
		} else {
			serverSelected = e.data as ServerInfo;
			if (serverSelected.ip != null) {
				this.selectedIpAddress = serverSelected.ip;
				if (serverSelected.passwordHash != null) {
					this.selectedPasswordHash = serverSelected.passwordHash;
					dispatchEvent(new Event("serverSelect"));
				} else {
					promptForPassword();
				}
			}
		}
	}

	private function promptForPassword():void {
		var login:PromptDialog=new PromptDialog();
		login.title="Enter password";
		login.message="Please enter the password for the server \"" + serverSelected.name + "\".";
		login.prompt = "Password:";
		login.displayAsPassword = true;
		login.addButton("OK");
		login.addEventListener(Event.SELECT, loginDialogHandler);
		login.show(IowWindow.getAirWindow().group);
		function loginDialogHandler(e:Event):void{
			selectedPasswordHash=CompRemote.hashPassword(login.text);
			dispatchEvent(new Event("serverSelect"));
		}
	}

	private function logError(message:String):void {
		var notice:AlertDialog=new AlertDialog();
		notice.title="Error!";
		notice.message=message;
		notice.addButton("OK");
		notice.show(IowWindow.getAirWindow().group);
	}

}

}
