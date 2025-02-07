import javax.sound.midi.*;
import processing.serial.*;
import garciadelcastillo.dashedlines.*;

// MIDI variables
MidiDevice midiDevice;

//Synthesizer
Synthesizer synth;
Receiver receiver;

final int NUM_CHANNELS = 16;
final int NUM_INSTRUMENTS = 128;
ArrayList<ChannelInfo> channelInfo = new ArrayList<ChannelInfo>();

//Sequencer
final int NUM_TRACKS = 4;
final int NUM_STEPS = 32;
int bpm = 120;
int bpmDisplay = 0;

Sequence sequence;
Sequencer sequencer;
float ticksPerStep = 0;
int currentTrack = 0;
int currentStep = 0;
boolean recording = false;

// MIDI variables
final int START_NOTE = 36;
final int END_NOTE = 84;
final int NUM_NOTES = END_NOTE - START_NOTE;

//Utils
DashedLines dash;
float dashDist = 0;

//Palette
color[] darkThemePalette = {
  #1B1B1E,  // Primary Background (Near Black)
  #222831,  // Dark Charcoal
  #2C3333,  // Deep Gray-Green
  #323F4B,  // Slate Gray
  #3B4252,  // Nord Dark Blue-Gray
  #4C566A,  // Secondary Text Gray
  #5C677D,  // Muted Steel
  #6D7078,  // Soft Graphite
  #1F2933,  // Midnight Blue-Black
  #283845,  // Cool Navy
  #A3BE8C,  // Soft Green (Success)
  #D08770,  // Warm Orange (Warning)
  #BF616A,  // Soft Red (Error)
  #81A1C1,  // Muted Blue (Selection)
  #EBCB8B,  // Gold Accent (Highlight)
  #ECEFF4   // High Contrast Text (Light Gray)
};

color[] synthwavePalette = {
  #FF6E67, #FFBB67, #FFEB67, #A6FF67,
  #67FFC1, #67D4FF, #6798FF, #C167FF,
  #FF67A0, #FF67D9, #FFFFFF, #000000,
  #FF4343, #FF9143, #FFD143, #67FF43
};

color[] activePalette = darkThemePalette;

int seqColor = activePalette[3];
int seqHColor = activePalette[10];
int seqCColor = activePalette[11];
int bgColor = activePalette[0];
int txtColor = activePalette[15];
int chColor = activePalette[13];
int nnColor = activePalette[12];
int nn1Color = activePalette[8];
int cNoteColor = activePalette[14];
int white = #FFFFFF;//activePalette[10];
int black = #000000; //activePalette[11];

//Interaction
int mousePressMillis;
long mousePressSeqTick;
int mousePressX;
int mousePressY;

//Serial COM
Serial sPort;
float knock = 500;
String message;

// Active notes
ArrayList<Note> notes = new ArrayList<Note>();

//Synestruments
int synestrumentHeight = height - 100;
int synestrumentWidth = width;
ArrayList<Synestrument> syns = new ArrayList<Synestrument>();

String insMessage;
int insName = 255;

Synestrument synestrument;
int currSyn = 0;

int currS = 0;
int currY = 0;
int gridX = 0;
int gridY = 0;

int x;
int y;

int ss = 50;

boolean drawPalette = false;
boolean bendEnabled = false;
int pitchBendChannel = 0;

void setup() {
  size(128 * 10, 50 * 16 + 110); // (END_NOTE - START_NOTE) * 15, 50 * NUM_CHANNELS
  background(bgColor);
  initMidi();
  initSerial();
  setBPM(bpm);
  createMidiSequence();

  //Create the synestruments
  synestrumentHeight = 50 * NUM_CHANNELS;  
  synestrumentWidth = width;  
  syns.add(new Keyano(0, 0, synestrumentWidth, synestrumentHeight));
  syns.add(new Beztar(0, 0, synestrumentWidth, synestrumentHeight));
  syns.add(new Feckof(0, 0, synestrumentWidth, synestrumentHeight));
  syns.add(new Bawler(0, 0, synestrumentWidth, synestrumentHeight));
  syns.add(new Pixelah(0, 0, synestrumentWidth, synestrumentHeight));
  
  //Set current synestrument
  showInstrument(syns.get(currSyn));

  dash = new DashedLines(this);
  
  for (int c = 0; c < NUM_CHANNELS; c++) {
    ChannelInfo ci = new ChannelInfo();
    ci.number = c;
    ci.instrumentIndex = 0;
    ci.instrumentName = c == 9 ? "Percussion" : "Piano1";
    channelInfo.add(ci);
  }
  
  //fullScreen();
  
  gridX = width / ss;
  gridY = synestrumentHeight / ss;
  x = width/2;
  y = synestrumentHeight/2;  
}

void draw() {
  background(bgColor);
  drawBpm();
  if (synestrument != null) {
    
    // Middle C Guide Line
    pushStyle();
    stroke(black, 128);
    strokeWeight(1);
    dash.pattern(2, 4);
    dash.line(synestrumentWidth / 2, 0, synestrumentWidth / 2, synestrumentHeight);
    popStyle();
    
    //Draw the current Synestrument
    synestrument.display();
    drawSynName();
  }
  
  drawSequencer();
  drawNotes();
  drawVis();
  if (drawPalette)
    drawPalette();
 
  if (key == 'f') {
    pushStyle();
    textAlign(CENTER, CENTER);
    fill(txtColor);
    text(""+frameRate, 0, 0, width, height);
    popStyle();
  }
}

void drawSynName() {
  pushStyle();
  if (insName > 0) {
    pushStyle();
    textSize(24);
    stroke(chColor, insName);
    strokeWeight(4);
    noFill();
    rect(width/2 - 300, synestrumentHeight/2 - 35, 600, 70, 12);
    noStroke();
    fill(white, insName);
    textAlign(CENTER, CENTER);
    textSize(64);
    text(insMessage, 0, 0, width, synestrumentHeight);
    popStyle();
    insName-=2.5;
  }
  popStyle();
}

void drawBpm() {
  if (bpmDisplay > 0) {
    pushStyle();
    fill(txtColor);
    textAlign(CENTER);
    textSize(200);
    text(""+bpm, 0, 0, width, synestrumentHeight);
    popStyle();
    bpmDisplay--;
  }
}

void drawPalette() {
  pushStyle();
  textSize(12);
  int w = width/activePalette.length;
  for (int i = 0; i < activePalette.length; i++) {
    noStroke();
    fill(activePalette[i]);
    rect(i * w, 10, w, 50);
    if (activePalette[i] == color(0))
      fill(255);
    else
      fill(0);
    text(hex(activePalette[i]).substring(2), i * w, 10, w, 50);
  }
  popStyle();
} //<>//

void drawNotes() {
  pushStyle();
  ArrayList<Note> notesDone = new ArrayList<Note>();
  for (int i = 0; i < notes.size(); i++) {
    Note note = notes.get(i);
    note.update();
    note.display();
    if (note.delay <= 0) {
      notesDone.add(note);
      stopNote(note);
    }
  }
  popStyle();
  
  notes.removeAll(notesDone);
}

void drawVis() {
  if (bendEnabled) {
    drawVis1();
    currS++;
    if (currS > gridX)  {
      currS = 0;
      currY += ss;
    }
    
    if (currY > height) {
      currY = 0;
    } 
  }
}

void drawVis1() {
  //Simulate serial event
  //if (frameCount % 5 == 0) {    
  //  knock = map(mouseX, 0, width, 500, 2000);
  //  onKnockCommand(knock);
  //}
  
  if (bendEnabled) {
    float f = map(knock, 0, 1023, 0, ss);
    int n = synestrument.getNote(currY);
    Note note = new Note(synth, currS * ss, currY, 0, n, 0, (int)f);
    note.noteColor = color(200, 200);
    addNote(note);
  }
}

void drawSequencer() {
  pushStyle();

  int trackHeight = (height - (synestrumentHeight + 5)) / NUM_TRACKS;

  noStroke();
  fill(activePalette[2]);
  rect(0, synestrumentHeight + currentTrack * trackHeight, width, trackHeight);
  strokeWeight(1);
  for (int s = 0; s < 32; s++) {
    for (int t = 0; t < NUM_TRACKS; t++) {
      int n = getNoteAtStep(sequence, t, s);
      if (n > 0) {
        noStroke();
        fill(lerpColor(nn1Color, nnColor, map((n - START_NOTE) * width/NUM_NOTES, 0, width/NUM_NOTES * NUM_NOTES, 0, 1)));
        rect(s * width/32, synestrumentHeight + t  * trackHeight, width/32-2, trackHeight, 2);
      }
    }
    
    pushStyle();
    dash.pattern(1, 5);
    strokeWeight(1);
    stroke(chColor);
    dash.line(0, synestrumentHeight + currentTrack * trackHeight, width, synestrumentHeight + currentTrack * trackHeight);
    dash.line(0, synestrumentHeight + (currentTrack + 1) * trackHeight, width, synestrumentHeight + (currentTrack + 1) * trackHeight);

    if (sequencer.isRunning()) {
      if (sequencer.getTickPosition() == s)
        stroke(seqHColor);
      else
        stroke(seqColor);
    }
    else
      stroke(currentStep == s ? seqHColor : seqColor);
      
    noFill();
    strokeWeight(4);
    rect(s * width/32, synestrumentHeight, width/32-4, trackHeight * NUM_TRACKS, 2);
    if (mouseY > synestrumentHeight) {
      fill(txtColor);
      textSize(20);
      textAlign(CENTER);
      text(""+s, s * width/32, height - 30, width/32-4, trackHeight * NUM_TRACKS);
    }
    popStyle();  
  }
  
  if (recording) {
    pushStyle();
    ellipseMode(CENTER);
    noStroke();
    fill(255, 0 , 0);
    ellipse(18, synestrumentHeight + (currentTrack * trackHeight) + trackHeight/2, 12, 12);
    popStyle();
  }
  
  popStyle();
}

void mouseMoved() {
  if (synestrument != null)
    synestrument.onMouseMoved();
}

void mouseDragged() {
  if (mouseY < synestrumentHeight) {    
    if (mouseButton == LEFT) {
      if (synestrument != null)
        synestrument.onLeftMouseDragged();
      return;
    }
    
    if (mouseButton == RIGHT) {
      if (synestrument != null)
        synestrument.onRightMouseDragged();
      return;
    }
  }
}

void mousePressed() {
  mousePressX = mouseX;
  mousePressY = mouseY;
  mousePressMillis = millis();
  mousePressSeqTick = sequencer.getTickPosition();
  
  if (mouseY < synestrumentHeight && synestrument != null) {
    if (mouseButton == LEFT) {
      synestrument.onLeftMousePressed();
    }
    if (mouseButton == RIGHT) {
      synestrument.onRightMousePressed();
    }
  }
}

void mouseReleased() {
  if (mouseButton == LEFT) {
    if (mousePressY > synestrumentHeight && mousePressY < height &&
        mouseY > synestrumentHeight && mouseY < height ) {
      //Select Sequencer Step
      currentStep = mouseX / (width/32);
    }
    else if (synestrument != null)
      synestrument.onLeftMouseReleased();
  }

  if (mouseButton == RIGHT) {
    if (synestrument != null)
      synestrument.onRightMouseReleased();
  }
  
  mousePressX = -1;
  mousePressY = -1;
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  if (synestrument != null) {
      if (synestrument.onMouseWheel(delta))
        return;
  }
        
  bpm += delta;
  setBPM(bpm); 
  bpmDisplay = 30;
}

long getCurrentDuration() {
  long duration = 0;
  if (sequencer.isRunning()) {
    long r = sequencer.getTickPosition();
    if (r < mousePressSeqTick)
      duration = NUM_STEPS - mousePressSeqTick + r;
    else
      duration = sequencer.getTickPosition() - mousePressSeqTick;
    }
  else {
    int tm = millis() - mousePressMillis;
    duration = (long)constrain(tm/(long)calculateMillisecondsPerTick(), 1, 32 - currentStep);
  }

  return duration;
}

void recordNote(Note note, long noteDuration) {
  if (recording) {
    //println("PRESS", noteDuration);
    long tick = (long)(currentStep * ticksPerStep);
    if (sequencer.isRunning())
      tick = mousePressSeqTick;
    //println("Record:",  tick, note.note, note.channel);
    ChannelInfo ci = channelInfo.get(note.channel);
    sequence.getTracks()[currentTrack].add(createProgramChangeEvent(note.channel, ci.instrumentIndex, tick));
    MidiEvent e = createNoteOnEvent(note.channel, note.note, note.volume, tick);
    sequence.getTracks()[currentTrack].add(e);
    long noteOffTick = Math.round(tick + noteDuration);
    sequence.getTracks()[currentTrack].add(createNoteOffEvent(note.channel, note.note, 0, noteOffTick));
    return;
  }
}

void showInstrument(Synestrument si) {
  synestrument = si;
  insName = 255;
  insMessage = synestrument.name();
}

void keyPressed() {
  
  if (synestrument != null)
      if (synestrument.onKeyPressed() == true)
        return;
      
  if (key == 'q') {
    currSyn++;
    if (currSyn == syns.size())
      currSyn = 0;
      
    showInstrument(syns.get(currSyn));
  }
  
  if (key == 'k') {
    currSyn = 0;
    showInstrument(syns.get(currSyn));
  }


  int ch = 0;
  if (synestrument != null) {
    ch = synestrument.getChannel();
  }
    
  ChannelInfo ci = channelInfo.get(ch);
  if (keyCode == LEFT) {
    if (recording) {
      currentStep -= 1;
      if (currentStep < 0)
        currentStep = 31;
      return;
    }
    
    int i = ci.instrumentIndex - 1;
    if (i < 0) i = 127;
    setProgram(ch, i);
    Note note = new Note(synth, width/2, ch * synestrumentHeight/NUM_CHANNELS + synestrumentHeight/NUM_CHANNELS/2, ch, 60, 100, 30); 
    insMessage = ci.instrumentName;
    insName = 255;
    addNote(note);
  }
  
  if (keyCode == UP) {
    currentTrack--;
    if (currentTrack < 0)
      currentTrack = NUM_TRACKS - 1;
  }
  
  if (keyCode == DOWN) {
    currentTrack++;
    if (currentTrack == NUM_TRACKS)
      currentTrack = 0;
  }
  
  if (keyCode == RIGHT) {
    if (recording) {
      currentStep += 1;
      if (currentStep > 31)
        currentStep = 0;
      return;
    }
    
    int i = ci.instrumentIndex + 1;
    if (i > 127) i = 0;
    setProgram(ch, i);
    Note note = new Note(synth, width/2, ch * synestrumentHeight/NUM_CHANNELS + synestrumentHeight/NUM_CHANNELS/2, ch, 60, 100, 30);
    insMessage = ci.instrumentName;
    insName = 255;
    addNote(note);
  }
  
  if (key == 'r') {
      recording = !recording;
  }

  if (key == 'c') {
    recording = false;
    sequencer.stop();
    Track[] tracks = sequence.getTracks(); // Get all tracks from the sequence
    for (int i = tracks.length - 1; i >= 0; i--) {
      sequence.deleteTrack(tracks[i]); // Delete each track from the sequence
    }
 
    createMidiSequence(); 
  }
 
   if (key == 'p') {
    if (sequencer.isRunning()) sequencer.stop();
    else
      playMidiSequence();
  }

  if (keyCode == ENTER) {
    saveFrame("frames\\softSynth#####.png");
  }
  
  if (key == 'd') drawPalette = !drawPalette;
  if (key == 'b') {
    bendEnabled = !bendEnabled;
    if (!bendEnabled) {
      for (int c = 0; c < NUM_CHANNELS; c++)
        synth.getChannels()[c].setPitchBend(8192);
    }
  }
}

void keyTyped() {
  if (key == '0') {
    for (int n = 0; n < notes.size(); n++) {
      Note nn = notes.get(n);
      nn.stop();
    }
    
    notes.clear();
  }
}

void addNote(Note note) {
    notes.add(note);
    note.play();
}

void stopNote(Note note) {
  if (synth != null) {
    note.stop();
  }
}

void setProgram(int channel, int programNumber) {
  if (synth != null && channel != 9) {
    try {
      // Change the program number (instrument) using CC message
      int ccNumber = 0x00; // Control Change number for Bank Select MSB
      int ccValue = 0x80; // Value for GM Bank (0x00 for GM1, 0x78 for GM2)
  
      synth.getChannels()[channel].controlChange(ccNumber, ccValue);
      
      // Change the program number (instrument) using Program Change message
      synth.getChannels()[channel].programChange(programNumber);
      ChannelInfo ci = channelInfo.get(channel);
      ci.instrumentIndex = programNumber;
      ci.instrumentName = synth.getLoadedInstruments()[programNumber].getName();
      //println("SetProgram:", channel, programNumber);
    }
    catch (Exception e) {
      println("EEEEEK", e);
    }
  }
}

void stop() {
  if (midiDevice != null && midiDevice.isOpen()) {
    midiDevice.close();
  }
  if (sequencer != null && sequencer.isOpen()) {
    sequencer.stop();
    sequencer.close();
  }
  super.stop();
}

void createMidiSequence() {
  try {
    sequence = new Sequence(Sequence.PPQ, 4);
    for (int t = 0; t < NUM_TRACKS; t++) {
      sequence.createTrack();   
      finalizeSequence(sequence, t);
    }
    sequencer.setSequence(sequence);
    ticksPerStep = sequence.getResolution() / 4; 
  } catch (InvalidMidiDataException e) {
    e.printStackTrace();
  }
}

void playMidiSequence() {
  if (sequencer != null && sequence != null) {
    try {
      sequencer.setLoopCount(Sequencer.LOOP_CONTINUOUSLY); // Loop the sequence continuously
      sequencer.start();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void setBPM(int bpm) {
  if (sequencer != null) {
    float tempoFactor = (float) (bpm) / 120.0f; // Calculate tempo factor
    sequencer.setTempoFactor(tempoFactor);
  }
}

void setInstrument(Track track, int channel, int instrument, long atTick) {
  ShortMessage programChange = new ShortMessage();
  try {
    programChange.setMessage(ShortMessage.PROGRAM_CHANGE, channel, instrument, 0);
    track.add(new MidiEvent(programChange, atTick)); // Set instrument at the start of the track
  } catch (InvalidMidiDataException e) {
    e.printStackTrace();
  }
}

long calculateNextTick() {
  long sequenceLengthInMicros = sequencer.getMicrosecondLength();
  float ticksPerMicro = sequencer.getTickLength() / (float) sequenceLengthInMicros;
  return sequencer.getTickPosition() + (long)(1000000 * ticksPerMicro); // Convert microseconds to ticks
}

void serialEvent(Serial port) {
  //Read from port
  String inString = port.readStringUntil('\n');
  if (inString != null) {
    //Trim
    inString = inString.trim();
    //Record it
    String[] values = new String[2];
    values[0] = Long.toString(System.currentTimeMillis());
    values[1] = inString;
    // Process the command
    String[] command = "BEND:IT".split(":");
    command[1] = trim(inString);
    
    switch(command[0]) {
      case "BEND":
        //println(inString);
        onBendCommand(float(command[1]) * 4);
        break;
      case "EXTCMD":
        println(inString);
        break;
      case "CC":
        println(inString);
        onControlChange(int(command[1]), int(command[2]), float(command[3]));
    }
  }
}

void onBendCommand(float k) {
  knock = k;
  float bend = 8192;
  if (synth != null && synestrument != null) {
    if (bendEnabled) bend = 8192 + random(-1, 1)*map(k, 0, 1023, 0, 8192);
    else
      bend = 8192;
    //println("BEND:", synestrument.getChannel(), knock);
    if (pitchBendChannel != synestrument.getChannel())
      synth.getChannels()[pitchBendChannel].setPitchBend(8192);

    pitchBendChannel = synestrument.getChannel();
    println("BENDING", pitchBendChannel, knock);
    synth.getChannels()[pitchBendChannel].setPitchBend(floor(bend));
  }
}

void onControlChange(int cc, int channel, float value) {}
