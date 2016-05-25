import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
 
import java.util.Iterator;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.imageio.ImageReadParam;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

public class SerialComm implements MessageListener {
  
  private static final byte CMD_FLASH_REQUEST = 0;
  private static final byte CMD_FLASH_START = 1;
  private static final byte CMD_FLASH_ACK = 2;
  private static final byte CMD_FLASH_END = 3;
  
  private static final byte CMD_RF_REQUEST = 10;
  private static final byte CMD_RF_START = 11;
  private static final byte CMD_RF_END = 12;

  private static boolean senderNode;

  private boolean requestAccepted = false;
  private byte[] image;
  private int chunkNr;
  private String imageFileName;

  private MoteIF moteIF;
  
  public SerialComm(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new SerialCmdMsg(), this);
    this.moteIF.registerListener(new SerialDataMsg(), this);
  }

  public void sendWriteRequest(byte[] image) {
    this.image = image;
    SerialCmdMsg payload = new SerialCmdMsg();
    
    try {
      while (!requestAccepted) {
	      System.out.println("Requesting image transfer to mote...");
	      payload.set_cmd(CMD_FLASH_REQUEST);
	      moteIF.send(0, payload);

	      try {Thread.sleep(1000);}
	      catch (InterruptedException exception) {}
      }
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }
  
  public void sendTransmitRequest() {
    SerialCmdMsg payload = new SerialCmdMsg();
    
    try {
      while (!requestAccepted) {
	      System.out.println("Requesting image transfer between motes...");
	      payload.set_cmd(CMD_RF_REQUEST);
	      moteIF.send(0, payload);

	      try {Thread.sleep(1000);}
	      catch (InterruptedException exception) {}
      }
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }
  
  public void sendReadRequest(String imageFileName) {
    this.imageFileName = imageFileName;
    SerialCmdMsg payload = new SerialCmdMsg();
    
    try {
      while (!requestAccepted) {
	      System.out.println("Requesting image transfer from mote...");
	      payload.set_cmd(CMD_FLASH_REQUEST);
	      moteIF.send(0, payload);

	      try {Thread.sleep(1000);}
	      catch (InterruptedException exception) {}
      }
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
    }
  }
  
  public void rfStart() {
    if(requestAccepted)
      return;
    System.out.println("Mote to mote transmission started...");
    requestAccepted = true;
  }
  
  public void flashStart() {
    if(requestAccepted)
      return;
      
    requestAccepted = true;
    chunkNr = 0;
    
    if(senderNode)
      sendNextChunk();
    else
      System.out.println("Waiting for image chunks from mote..."); 
  }
  
  public void sendNextChunk() {
    if(chunkNr >= 65536 / 32) {
      System.out.println("Image sent!"); 
      return;
    }
  
    SerialDataMsg payload = new SerialDataMsg();
    short[] chunk = new short[32];
    
    try {
      System.out.println("Sending 32 byte chunk " + (chunkNr+1) + " of " + (65536 / 32) + "...");
    
      for(int j = 0; j < 32; j++)
	      chunk[j] = image[32*chunkNr+j];

	    payload.set_data(chunk);
	    moteIF.send(0, payload);
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending chunks. Exiting.");
      System.err.println(exception);
      requestAccepted = false;
    }
    chunkNr++; 
  }

  public void messageReceived(int to, Message message) {
  //System.out.println("data received" + (message instanceof SerialCmdMsg) + " " + (message instanceof SerialDataMsg));
    if(message instanceof SerialCmdMsg) {
      SerialCmdMsg msg = (SerialCmdMsg)message;
      //System.out.println("Received command " + msg.get_cmd());
      switch(msg.get_cmd()) {
        case CMD_FLASH_START:
          flashStart();
          break;
        case CMD_FLASH_ACK:
          sendNextChunk();
          break;
        case CMD_RF_START:
          rfStart();
          break;
        case CMD_FLASH_END:
        case CMD_RF_END:
          System.out.println("Mote back in IDLE state!");
          System.exit(0);
          break;
        default:
          break;
      }
    } else if(message instanceof SerialDataMsg) {
      
    }
  }
  
  private static void usage() {
    System.err.println("usage:");
    System.err.println("-> transfer image to mote:           TestSerial <source> w <filename>");
    System.err.println("-> transfer image from mote:         TestSerial <source> r <filename>");
    System.err.println("-> transfer image from mote to mote: TestSerial <source> t");
    System.err.println("");
    System.err.println("e.g.: TestSerial serial@/dev/ttyUSB0:telosb w aerial.tiff\n");
  }
  
  private static byte[] imageFromFile(String fileName) throws IOException { 
		File file = new File(fileName);
    FileInputStream fis = new FileInputStream(file);
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    byte[] buf = new byte[1024];
    try {
        for (int readNum; (readNum = fis.read(buf)) != -1;) {
            bos.write(buf, 0, readNum); 
        }
    } catch (IOException ex) {
        System.err.println("Error while reading image.");
    }

    byte[] bytes = bos.toByteArray();
 
    System.out.println("image size : " + bytes.length);
    return bytes;
  }
  
  public static void main(String[] args) throws Exception {  
    String source = args[0];

    PhoenixSource phoenix;
    phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    
    if(phoenix == null)
      usage();

    MoteIF mif = new MoteIF(phoenix);
    SerialComm serial = new SerialComm(mif);
    
    String cmd = args[1];
    
    if(cmd.equals("w")) {
      senderNode = true;
      byte[] image = imageFromFile(args[2]);
      serial.sendWriteRequest(image);
    } else if (cmd.equals("t")) {
      serial.sendTransmitRequest();
    } else if (cmd.equals("r")) {
      senderNode = false;
      serial.sendReadRequest(args[2]);
    }
  }
}
