final int OCTAVE = 12;

class Note extends Sprite {
  Synthesizer synth;
  int channel;
  int ogNote;
  int note;
  int volume;
  long delay;
  long initialDelay;
  int repeat;
  int decay = -OCTAVE;
  
  PopupMessage pm;
  
  Note(Synthesizer s, float x, float y, int c, int n, int v, int d) {
    super(x, y, d, d);
    synth = s;
    channel = c;
    ogNote = note = n;
    volume = v;
    initialDelay = delay = d;
    repeat = 0;
  }
  
  boolean mouseIn() {
    if (mouseX >= position.x - width/2 &&
      mouseX <= position.x + width/2 &&
      mouseY >= position.y - height/2 &&
      mouseY <= position.y + height/2)
      return true;

    return false;
  }
  
  void setMessage(String msg) {
    //pm = new PopupMessage(position.x + delay/2 - 100, position.y + delay/2 - 25, msg, delay/2);
    pm = new PopupMessage(position.x, position.y, msg, (int)delay);
  }
  
  void play() {
    //println("NoteOn:CH:"+channel+" N:"+note+" V:"+volume);
    synth.getChannels()[channel].noteOn(note, volume);
  }
  
  void stop() {
    synth.getChannels()[channel].noteOff(note);
  }
  
  void update() {
    if (delay > 0) {
      if (repeat > 0 && delay % repeat == 0) {
        stop();
        note += decay;
        if (note == ogNote - OCTAVE || note == ogNote + OCTAVE)
          decay = -(decay);         
        
        volume -= 3;
        play();
      }
      delay--;
    }
    
    if (pm != null) pm.update();
  }
  
  void display() {
    pushStyle();
    ellipseMode(CENTER);
    stroke(lerpColor(nn1Color, nnColor, map(note, START_NOTE, END_NOTE, 0, 1)), map(delay, 0, initialDelay, 0, 255));
    if (delay > 200) {
      strokeWeight(2);
      noFill();
    }
    else
      fill(lerpColor(nn1Color, nnColor, map(note, START_NOTE, END_NOTE, 0, 1)), map(delay, 0, initialDelay, 0, 255));
    ellipse(position.x, position.y, delay, delay);
    if (pm != null) pm.display();
    
    if (mouseIn() && volume != -1) {
      fill(white);
      textAlign(CENTER,CENTER);
      text(""+volume, position.x - delay/2, position.y-10, delay, 20);
    }
    popStyle();
  }
}
