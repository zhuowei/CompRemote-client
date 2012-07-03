package {

public class ServerInfo {
	public var ip:String;
	public var passwordHash:String;
	public var name:String;

	public function toString():String {
		return name + ": " + ip;
	}

	public function get label():String {
		return name + ": " + ip;
	}
}

}
