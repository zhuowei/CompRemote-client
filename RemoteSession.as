package {
import flash.net.*;
public class RemoteSession{
	public var sock:Socket;
	public function RemoteSession(socket:Socket){
		this.sock=socket;
	}
	/** Send Authentication. The password is sent in <b>PLAIN TEXT!</b>
	* Thus, it must be hashed before it is passed in. 
	*/
	public function auth(password:String):void{
		sock.writeByte(0); //initial link
		sock.writeUTF(password);
		sock.flush();
	}
	public function mouseDown(button:int):void{
		trace("down" + button);
		sock.writeByte(3);
		sock.writeByte(getButtonCode(button));
		sock.flush();
	}
	public function mouseUp(button:int):void{
		trace("up" + button);
		sock.writeByte(4);
		sock.writeByte(getButtonCode(button));
		sock.flush();
	}
	private function getButtonCode(button:int):int{
		if(button==1){
			return 16;
		}
		if(button==2){
			return 8;
		}
		if(button==3){
			return 4;
		}
		trace("fail");
			return 0;
	}
	public function mouseMove(x:int, y:int):void{
		sock.writeByte(5);
		trace(x + " : " + y);
		sock.writeInt(x);
		sock.writeInt(y);
		sock.flush();
	}
	public function mouseWheel(notches:int):void{
		sock.writeByte(6);
		sock.writeByte(notches);
		sock.flush();
	}

	public function keyPress(keycode:int):void{
		sock.writeByte(1);
		sock.writeShort(keycode);
		sock.flush();
	}

	public function keyRelease(keycode:int):void{
		sock.writeByte(2);
		sock.writeShort(keycode);
		sock.flush();
	}
}
}
