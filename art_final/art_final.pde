import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

import gab.opencv.*;
import java.awt.Rectangle;
import java.util.ArrayList;
import processing.serial.*;


Serial myPort;  // Create object from Serial class
String in;     // Data received from the serial port
OpenCV opencv;
Rectangle[] bounding_boxes;
ArrayList<PImage> faces = new ArrayList<PImage>();
PImage src;
float x_input,y_input;

PostFX fx;
PShader shader;


void setup() {
  size(1080, 720, P3D);
  
  src = loadImage("test.png");
  opencv = new OpenCV(this, src);
  
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
   myPort = new Serial(this, "COM3",  115200); // change "/dev/ttyUSB0" to portName
}

void draw() {
  //change color of background over time and in response to mouse position
  float t = 50 + 30 * sin( frameCount * 0.05f );
  float t2 = map(x_input+y_input, 0, width+height, 100, 0);
  background(t+t2, t+t2/2, t);
  
// set shader parameters so morph speed depends on mouse position
  shader.set("fraction", (float)map(x_input+y_input, 0, width+height, 2, 0));
  shader.set("frameCount", (float)frameCount);
  
  shader(shader);
  

  float z = (height/2) / tan(PI/6);
  camera(mouseX, height/2, z + map(mouseX+mouseY, 0, width+height, 1000, -z/2), width/2, height/2, 0, 0, 1, 0);
  noFill();
  //stroke(0, 255, 0);
  strokeWeight(2);
  
  
  // show bounding boxes on the original image in the background
  //for (int i = 0; i < bounding_boxes.length; i++) {
  //  rect(bounding_boxes[i].x, 
  //  bounding_boxes[i].y, 
  //  bounding_boxes[i].width, 
  //  bounding_boxes[i].height);
  //}

  translate(width / 2, height / 2, 100);
  float sphereZ = map(constrain(x_input+y_input, 0, (width+height)/2), 0, (width+height)/2, 200, 0);
    
  for (int i = 0; i < faces.size(); i++) {
    PImage img = faces.get(i);

    rotateY(map(x_input, 0, width, -PI, PI));
    rotateZ(map(x_input, 0, height, -PI, PI));
    beginShape();
    texture(img);
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
    .saturationVibrance(map(x_input+y_input, 0, width+height, -1, 0.2), map(x_input+y_input, 0, width+height, -1, 0.2))
    .pixelate(map(x_input+y_input, 0, width+height, width/3, width))
    .noise(map(x_input+y_input, 0, width+height, 0.3, 0),
          map(x_input+y_input, 0, width+height, 1, 0))
    .compose();
}

// Everytime we receive a packet from the CPE this is called
void serialEvent(Serial myPort) {
  
  try {
    //put the incoming data into a String - 
    //the '\n' is our end delimiter indicating the end of a complete packet
    in = myPort.readStringUntil('\n');
    // Expects inputs of the format:
    // X: ###, Y: ###, Z: ###,
    // Where ## are the readings from the CPE
    
    //make sure our data isn't empty before continuing
    if (in != null) {
      //trim whitespace and formatting characters (like carriage return)
      in = trim(in);
      // Split by commas
      String comma[] = in.split(",");
      // Parse values and calculate angles
      float x, y, z, theta_x, theta_y; 
      x = float(comma[0].split(":")[1]);
      y = float(comma[1].split(":")[1]);
      z = float(comma[2].split(":")[1]);
      theta_x = atan2(x, y); 
      theta_y = atan2(z, y); 
      
      print("X: "); println(x);
      print("Y: "); println(y);
      print("Z: "); println(z);
      print("Theta X: "); println(theta_x);
      print("Theta Z: "); println(theta_y);
      println();
      
      x_input = map(theta_x, -PI, PI, 0, width);
      y_input = map(theta_y, -PI, PI, 0, height);
    }
  }
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}
