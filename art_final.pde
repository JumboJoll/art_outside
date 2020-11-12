import gab.opencv.*;
import java.awt.Rectangle;
import java.util.ArrayList;


OpenCV opencv;
Rectangle[] bounding_boxes;
ArrayList<PImage> faces = new ArrayList<PImage>();
PImage src;

void setup() {
  src = loadImage("test.png");
  opencv = new OpenCV(this, src);
  size(1080, 720, P3D);

  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  bounding_boxes = opencv.detect();
  for (int i = 0; i < bounding_boxes.length; i++) {
    faces.add(src.get(bounding_boxes[i].x, bounding_boxes[i].y, bounding_boxes[i].width, bounding_boxes[i].height));
  }
}



void draw() {
  background(0);
  //image(opencv.getInput(), 0, 0);
  camera(mouseX, height/2, (height/2) / tan(PI/6), width/2, height/2, 0, 0, 1, 0);
  noFill();
  //stroke(0, 255, 0);
  strokeWeight(2);
  //for (int i = 0; i < bounding_boxes.length; i++) {
  //  rect(bounding_boxes[i].x, bounding_boxes[i].y, bounding_boxes[i].width, bounding_boxes[i].height);
  //}

  translate(width / 2, height / 2);
  int x = 0;
  for (int i = 0; i < faces.size(); i++) {
    PImage img = faces.get(i);

    rotateY(map(mouseX, 0, width, -PI, PI));
    rotateZ(map(mouseY, 0, height, -PI, PI));
    beginShape();
    texture(img);
    vertex(-100, -100, 0, 0, 0);
    vertex(100, -100, 0, img.width, 0);
    vertex(100, 100, 0, img.width, img.height);
    vertex(-100, 100, 0, 0, img.height);
    endShape();
  }
}
