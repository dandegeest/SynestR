final static int[] circleOF = {60, 67, 62, 69, 64, 71, 66, 61, 68, 63, 70, 65};
int findCoF(int nn) {
  for (int n = 0; n < circleOF.length; n++) {
    if (circleOF[n] == nn)
      return n;
  }
  
  return -1;
}

class Feckof extends Synestrument {
  int segments = circleOF.length;
  float radius = 150;
  float angleIncrement = TWO_PI / segments;
  int dir = 1;
  int octave = 0;
  int octaveDisplay = 0;
  Note mouseNote;
  int noteMode = 3;
  int channel = 0;

  String[] noteNames = {"C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"};
  
  ArrayList<Note> circle = new ArrayList<Note>();
  
  Feckof(float x, float y, int w, int h) {
    super(x, y, w, h);
    radius = (h - 300)/2;
    initCof();
  }
  
  String name() { return "FekCOF"; }
  int getChannel() {
    return channel;
  }
  
  int getNote(int pos) {
    int note = (int)map(pos, 0, height/NUM_NOTES * NUM_NOTES, START_NOTE, END_NOTE);
    return note;
  }
  
  String getNoteName(int n) {
    for (int i = 0; i < segments; i++) {
      if (circleOF[i] == n) return noteNames[i];
    }
    return "";
  }
  
  void display() {    
    pushStyle();
    noFill();
    stroke(activePalette[15], 220);
    strokeWeight(0);
    for (int i = 0; i < width; i+=5) {
      for (int j = 0; j < height; j+=5) {
        rect(i, j, 5, 5);
      }
    }
    popStyle();

    for (int i = 0; i < circle.size(); i++) {
      Note n = circle.get(i);
      n.display();
      pushStyle();
      fill(white, 128);
      textSize(36);
      textAlign(CENTER, CENTER);
      text(getNoteName(n.note), n.position.x - 50, n.position.y - 50, 100, 100);
      popStyle();
    }
    
    for (int i = 0; i < 6; i++) {
      //Octave bars
      pushStyle();
      stroke(0);
      fill(activePalette[8+i], 255);
      noStroke();
      rect(0, i * height/6, 200, height/6, 12);
      rect(width - 200, i * height/6, 200, height/6, 12);     
      popStyle();
    }
    
    int cw = (synestrumentWidth-400)/NUM_CHANNELS;
    for (int i = 0; i < NUM_CHANNELS; i++) {
      //Chanel bars
      pushStyle();
      strokeWeight(0);
      stroke(chColor);
      fill(lerpColor(activePalette[5],activePalette[15], map(i, 0, NUM_CHANNELS, 0, 1)));
      rect(200 + i * cw, 0, cw, 40, 12);
      if (i == getChannel()) {
        textSize(34);
        textAlign(CENTER, CENTER);
        fill(white, octaveDisplay);
        text(""+i, 200 + i * cw, 0, cw, 40);
      }
      popStyle();
    }
    
    // Current octave
    // Chord or note mode?
    if (octaveDisplay > 0) {      
      pushStyle();
      strokeWeight(0);
      stroke(chColor);
      ellipseMode(CENTER);

      fill(white, octaveDisplay);
      for (int i = 0; i < noteMode; i++) {
        ellipse(width/2, height/2 + i * 20 - 48, 16, 16);
      }

      for (int i = 0; i < 6; i++) {
        if (i <= map(octave, -20, 30, 0, 5))
          fill(activePalette[1], octaveDisplay);
        else
          fill(white, octaveDisplay);
        ellipse(width/2 + i * 20 - 60, height/2 - 8, 16, 16);
      }

      octaveDisplay -= 5;
      popStyle();
    }
  }
  
  void initCof() {
    for (int i = 0; i < segments; i++) {
      float angle = -HALF_PI + angleIncrement * i; // Start from 12 o'clock position
      float x = cos(angle) * radius + width/2;
      float y = sin(angle) * radius + height/2;
      
      circle.add(new Note(synth, x, y, 0, circleOF[i], -1, 100));
    }
  }
  
  boolean onKeyPressed() {
    if (key == '1') {
      noteMode = noteMode == 1 ? 3 : 1;
      octaveDisplay = 255;
    }
      
    return false;
  }
  
  void onLeftMouseReleased() {
    if (mouseX <= 200 || mouseX > width - 200) {
      for (int i = 0; i < 6; i++) {
        if (mouseY > i * height/6 &&
            mouseY < (i == 5 ? height : (i + 1) * height/6)) {
              octave = (int)map(i, 0, 5, -2, 3);
              octaveDisplay = 255;
            }
      }
      return;
    }

    if (mouseX > 200 && mouseX < width - 200 && mouseY < 40) {
      for (int i = 0; i < NUM_CHANNELS; i++) {
         channel = (int)map(mouseX, 200, width-200, 0, NUM_CHANNELS);
         octaveDisplay = 255;
      }
      return;
    }

    for (int i = 0; i < circle.size(); i++) {
      Note cn = circle.get(i);
      if (cn.mouseIn()) {
        int[] chord = new int[3];
        chord[0] = i % segments;
        chord[1] = (i+1) % segments;
        chord[2] = (i+4) % segments;   
        //println(noteNames[chord[0]],noteNames[chord[1]],noteNames[chord[2]]);
        for (int n = 0; n < noteMode; n++) {
          Note note = circle.get(chord[n]);
          int nd = floor((millis() - mousePressMillis) * 1.5);
          int cd = (int)dist(mouseX, mouseY, cn.position.x, cn.position.y);
          int v = (int)map(cd, 0, 50, 100, 50);
          Note nn = new Note(synth, mouseX, mouseY, getChannel(), note.note + octave*segments, v, nd);
          nn.repeat = 100;
          addNote(nn);
          recordNote(nn, 1);
        }
        
        mouseNote = cn;
        return;
      }
    }
    mouseNote = null;
  }
  
  void onLeftMouseDragged() {
    if (mouseX <= 200 || mouseX > width - 200) {
      for (int i = 0; i < 6; i++) {
        if (mouseY > i * height/6 &&
            mouseY < (i == 5 ? height : (i + 1) * height/6)) {
              octave = (int)map(i, 0, 5, -2, 3);
              octaveDisplay = 255;
        }
      }
      return;
    }
    
    if (mouseX > 200 && mouseX < width - 200 && mouseY < 40) {
      for (int i = 0; i < NUM_CHANNELS; i++) {
         channel = (int)map(mouseX, 200, width-200, 0, NUM_CHANNELS);
         octaveDisplay = 255;
      }
      return;
    }

    for (int i = 0; i < circle.size(); i++) {
      Note cn = circle.get(i);
      if (cn.mouseIn()) {
        if (cn == mouseNote)
          return;
          
        int tm = floor((millis() - mousePressMillis) * 1.5);
        int[] chord = new int[3];
        chord[0] = i % segments;
        chord[1] = (i+1) % segments;
        chord[2] = (i+4) % segments;   
        //println(noteNames[chord[0]],noteNames[chord[1]],noteNames[chord[2]]);
        for (int n = 0; n < noteMode; n++) {
          Note note = circle.get(chord[n]);
          int nd = millis() - mousePressMillis; //constrain((int)dist(mousePressX, mousePressY, mouseX, mouseY), 15, 100);
          int v = constrain((int)dist(mousePressX, mousePressY, mouseX, mouseY), 0, 127);
          Note nn = new Note(synth, mouseX, mouseY, getChannel(), note.note + octave*segments, v, nd);
          addNote(nn);
          long duration = (long)constrain(tm/(long)calculateMillisecondsPerTick(), 1, 32 - currentStep);
          recordNote(nn, duration);
        }
        
        mouseNote = cn;
        return;
      }
    }
    mouseNote = null;
  } 
}
