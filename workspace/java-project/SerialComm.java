import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class SerialComm implements MessageListener {

  private MoteIF moteIF;
  
  public SerialComm(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new SerialCmdMsg(), this);
  }

  public void sendPackets() {
    short cmd = 0;
    SerialCmdMsg payload = new SerialCmdMsg();
    
    try {
      while (true) {
	      System.out.println("Sending packet " + cmd);
	      payload.set_cmd(cmd);
	      moteIF.send(0, payload);
	      cmd++;
	      try {Thread.sleep(1000);}
	      catch (InterruptedException exception) {}
      }
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }

  public void messageReceived(int to, Message message) {
    SerialCmdMsg msg = (SerialCmdMsg)message;
    System.out.println("Received command " + msg.get_cmd());
  }
  
  private static void usage() {
    System.err.println("usage: TestSerial <source>");
    System.err.println(" e.g.: TestSerial serial@/dev/ttyUSB0:telosb\n");
  }
  
  public static void main(String[] args) throws Exception {  
    String source = args[0];

    PhoenixSource phoenix;
    phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    
    if(phoenix == null)
      usage();

    MoteIF mif = new MoteIF(phoenix);
    SerialComm serial = new SerialComm(mif);
    serial.sendPackets();
  }
}
