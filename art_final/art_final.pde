import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

import gab.opencv.*;
import java.awt.Rectangle;
import java.util.ArrayList;
import processing.serial.*;
import javax.swing.JOptionPane;



Serial myPort;  // Create object from Serial class
String in;     // Data received from the serial port
OpenCV opencv;
Rectangle[] bounding_boxes;
ArrayList<PImage> faces = new ArrayList<PImage>();
PImage src;
PImage bg;
float x_input,y_input;
float raw_x,raw_y,raw_z;
final boolean debugPort = true; 


PostFX fx;
PShader shader;


void setup() {
  size(1900, 1200, P3D);
  //getPort();
  
  src = loadImage("zoomEmbodiedInterfaces.jpg"); 
  opencv = new OpenCV(this, src);
  
  bg = loadImage("zoomEmbodiedInterfacesFaceless.jpg");
  bg.resize(width, height);
  
   // load shaders
   fx = new PostFX(this);  
  shader = loadShader("Frag.glsl","Vert.glsl");
  shader.set("frameCount", 0);

  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  bounding_boxes = opencv.detect();
  for (int i = 0; i < bounding_boxes.length; i++) {
    faces.add(src.get(bounding_boxes[i].x, bounding_boxes[i].y, bounding_boxes[i].width, bounding_boxes[i].height));
  }
  
  print(Serial.list()[0]);
  // Change this to connect with arduino on your computer
  
   String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
   myPort = new Serial(this, portName,  9600); // change "/dev/ttyUSB0" to portName
}

//void getPort() {
//  // Allow user to choose serial port
//    String COMx = "";
//    try {
//      if(debugPort) printArray(Serial.list());
//      int numPorts = Serial.list().length;
//       if (numPorts != 0) {
//        if (numPorts >= 2) {
//          COMx = (String) JOptionPane.showInputDialog(null, 
//          "Select COM port", 
//          "Select port", 
//          JOptionPane.QUESTION_MESSAGE, 
//          null, 
//          Serial.list(), 
//          Serial.list()[0]);
   
//          if (COMx == null) exit();
//          if (COMx.isEmpty()) exit();
//        }
//        myPort = new Serial(this, COMx, 9600); // change baud rate to your liking
//        myPort.bufferUntil('\n'); // buffer until CR/LF appears, but not required..
//      }
//      else {
//        JOptionPane.showMessageDialog(frame,"Device is not connected to the PC");
//        exit();
//      }
//    }
//    catch (Exception e)
//    { //Print the type of error
//      JOptionPane.showMessageDialog(frame,"COM port " + COMx + " is not available (maybe in use by another program)");
//      println("Error:", e);
//      exit();
//    }
//}

void draw() {
  //change color of background over time and in response to mouse position
  float t = 50 + 10 * sin( frameCount * 0.05f );
  float t2 = map(x_input+y_input, 0, width+height, 100, 0);
  bg.resize(width, height);
  background(bg);
  tint(t+t2, t+t2/2, t); //Changed to tint so we can use an image as the background
  
// set shader parameters so morph speed depends on mouse position
  shader.set("fraction", (float)map(x_input+y_input, 0, width+height, 2, 0));
  shader.set("frameCount", (float)frameCount);
  
  shader(shader);
  

  float z = (height/2) / tan(PI/6);
  camera(raw_x*30, raw_y*30 + height/2, raw_z*30 + map((raw_x+raw_y)*1.5, 0, width+height, 1000, -raw_z/2), width/2, height/2, 0, 0, 1, 0); //Mess with this if you want the object to move more in space
  noFill();
  //stroke(0, 255, 0);
  strokeWeight(2);
  
  // //show bounding boxes on the original image in the background
  //for (int i = 0; i < bounding_boxes.length; i++) {
  //  rect(bounding_boxes[i].x, 
  //  bounding_boxes[i].y, 
  //  bounding_boxes[i].width, 
  //  bounding_boxes[i].height);
  //}

  translate(width / 2 - 500, height / 2, 600);
  float sphereZ = map(constrain(x_input+y_input, 0, (width+height)/2), 0, (width+height)/2, 200, 0);
    
  for (int i = 0; i < faces.size(); i++) {
    PImage img = faces.get(i);

    rotateY(map(x_input, 0, width, -PI, PI));
    rotateZ(map(x_input, 0, height, -PI, PI));
    beginShape();
    texture(img);
    noTint(); //Limit the impact of the tint so it doesn't overwhelm
    float distance = (i - i/2) * sphereZ;
    vertex(-100 + distance, -100 + distance, sphereZ, 0, 0);
    vertex(100 + distance, -100 + distance, sphereZ, img.width, 0);
    vertex(100 + distance, 100 + distance, sphereZ, img.width, img.height);
    vertex(-100 + distance, 100 + distance, sphereZ, 0, img.height);
    endShape();
  }
  
  // add postfx
  fx.render()
    .vignette(map(x_input+y_input, 0, width+height, 2, 0), 0.35)
    .saturationVibrance(map(x_input+y_input, 0, width+height, -1, 0.5), map(x_input+y_input, 0, width+height, -1, 0.5))
    .pixelate(map(x_input+y_input, 0, width+height, width/3, width))
    .noise(map(x_input+y_input, 0, width+height, 0.3, 0),
          map(x_input+y_input, 0, width+height, 1, 0))
    .compose();
}

// Everytime we receive a packet from the CPE this is called
void serialEvent(Serial myPort) {
  
  try {
    //println("data received!");
    
    //put the incoming data into a String - 
    //the '\n' is our end delimiter indicating the end of a complete packet
    in = myPort.readStringUntil('\n');
    // Expects inputs of the format:
    // X: ###, Y: ###, Z: ###,
    // Where ## are the readings from the CPE
    println(in);
    
    //make sure our data isn't empty before continuing
    if (in != null) {
      //trim whitespace and formatting characters (like carriage return)
      in = trim(in);
      // Split by commas
      String comma[] = in.split(",");
      // Parse values and calculate angles
      float theta_x, theta_y; 
      raw_x = float(comma[0].split(":")[1]);
      raw_y = float(comma[1].split(":")[1]);
      raw_z = float(comma[2].split(":")[1]);
      theta_x = atan2(raw_x, raw_y); 
      theta_y = atan2(raw_z, raw_y); 
      
      print("X: "); println(raw_x);
      print("Y: "); println(raw_y);
      print("Z: "); println(raw_z);
      print("Theta X: "); println(theta_x);
      print("Theta Z: "); println(theta_y);
      println();
      
      x_input = 3*x_input/4 + map(theta_x, -PI, PI, 0, width)/4; //Change these ratios for smoothness! The ratios should add up to 1.
      y_input = 3*y_input/4 +  map(theta_y, -PI, PI, 0, height)/4; //Could add a small amount to the theta_x and theta_y over time for the choreo idea. May need bounds.
    }
  }
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}
