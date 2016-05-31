import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
 
public class SerialComm implements MessageListener {
  
  private static final byte CMD_FLASH_REQUEST = 0;
  private static final byte CMD_FLASH_START = 1;
  private static final byte CMD_FLASH_ACK = 2;
  private static final byte CMD_FLASH_END = 3;
  
  private static final byte CMD_RF_REQUEST = 10;
  private static final byte CMD_RF_START = 11;
  private static final byte CMD_RF_END = 12;
  
  private static final int DATA_PAYLOAD_SIZE = 64;

  private static boolean senderNode;

  private boolean requestAccepted = false;
  private byte[] image = new byte[256*256];
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
  
  public void sendAck() {
    SerialCmdMsg payload = new SerialCmdMsg();
    
    try {
      payload.set_cmd(CMD_FLASH_ACK);
	    moteIF.send(0, payload);
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending ACK. Exiting.");
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
    percent = -1;
    
    if(senderNode)
      sendNextChunk();
    else
      System.out.println("Waiting for image chunks from mote..."); 
  }
  
  int percent;
  
  private void printPercent() {
    if(Math.floor(((double)(chunkNr*DATA_PAYLOAD_SIZE)/65536)*100) > percent) {
      percent = (int)Math.floor(((double)(chunkNr*DATA_PAYLOAD_SIZE)/65536)*100);
      System.out.print("\r" + percent + "%");
    }
  }
  
  public void sendNextChunk() {
    if(chunkNr >= 65536 / DATA_PAYLOAD_SIZE) {
      System.out.print("\rImage sent!\n"); 
      return;
    }
  
    SerialDataMsg payload = new SerialDataMsg();
    short[] chunk = new short[DATA_PAYLOAD_SIZE];
    
    try {
      printPercent();

      for(int j = 0; j < DATA_PAYLOAD_SIZE; j++)
	      chunk[j] = image[DATA_PAYLOAD_SIZE*chunkNr+j];

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
    if(message instanceof SerialCmdMsg) {
      SerialCmdMsg msg = (SerialCmdMsg)message;
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
        printPercent();
        
        SerialDataMsg msg = (SerialDataMsg)message;        
        for(int j = 0; j < DATA_PAYLOAD_SIZE; j++)
	        image[DATA_PAYLOAD_SIZE*chunkNr+j] = (byte)(msg.get_data()[j]);
        chunkNr++;
        
        sendAck();
        
        if(chunkNr >= 65536 / DATA_PAYLOAD_SIZE) {
          System.out.print("\rImage received!\n");
          try {
            imageToFile(imageFileName, image);
          } catch (IOException exception) {
            System.err.println("Exception thrown when saving image. Exiting.");
            System.err.println(exception);
          }
        }
    }
  }
  
  private static void usage() {
    System.err.println("usage:");
    System.err.println("-> transfer image to mote:           TestSerial <source> w <filename>");
    System.err.println("-> transfer image from mote:         TestSerial <source> r <filename>");
    System.err.println("-> transfer image from mote to mote: TestSerial <source> t");
    System.err.println("");
    System.err.println("e.g.: SerialComm serial@/dev/ttyUSB0:telosb w img/aerial.tiff");
    System.err.println("      SerialComm serial@/dev/ttyUSB0:telosb t");
    System.err.println("      SerialComm serial@/dev/ttyUSB0:telosb r aerial-received.png\n");
  }
  
  private static byte[] imageFromFile(String fileName) throws IOException { 
    try {
      Process p = Runtime.getRuntime().exec("python img2bin.py " + fileName + " /tmp/binaryimage.bin");
      p.waitFor();
    } catch (Exception exception) {
      System.err.println("Exception thrown when converting image. Exiting.");
      System.err.println(exception);
    } 
  
		File file = new File("/tmp/binaryimage.bin");
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
  
  private static void imageToFile(String fileName, byte[] bytes) throws IOException {
    FileOutputStream fos = new FileOutputStream("/tmp/binaryimage.bin");
    fos.write(bytes);
    fos.close();
    
    try {
      Process p = Runtime.getRuntime().exec("python bin2img.py /tmp/binaryimage.bin " + fileName);
      p.waitFor();
    } catch (Exception exception) {
      System.err.println("Exception thrown when converting image. Exiting.");
      System.err.println(exception);
    } 
    
    System.out.println("Saved image to " + fileName);
  }
  
  public static void main(String[] args) throws Exception {  
    if(args.length < 2) {
      usage();
      return;
    }
  
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
