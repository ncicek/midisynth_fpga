#include<stdio.h>
#include<stdint.h>

#include "midi_handler.h"

#define NOTEON 0x90
#define NOTEOFF 0x80
#define CC 0xB0
#define PRESSURE 0xD0
#define ATTACK_CC 0x4A
#define DECAY_CC 0x47
#define SUSTAIN_CC 0x5B
#define RELEASE_CC 0x5D
#define FILTER_CC 0x01

struct voice
{
  uint8_t midi_note;
  uint8_t note_state;
};

void parseMidi(uint8_t MIDI_Message[]) {
  static struct voice voice_table[NUMBER_OF_VOICES];
  static uint8_t voice_index=0;

	//check that we got a proper midi message
	if (checkifbyteis(MIDI_Message[0], NOTEON) || checkifbyteis(MIDI_Message[0], NOTEOFF) || checkifbyteis(MIDI_Message[0], CC)){
		if ((MIDI_Message[1] >> 7) == 0 || (MIDI_Message[2] >> 7) == 0){  //8th bit of valid data bytes should always be 0
			if (checkifbyteis(MIDI_Message[0], NOTEON) && MIDI_Message[2] > 0){
			  voice_index = handleNoteOn(voice_table, voice_index, MIDI_Message[1], MIDI_Message[2]);
      }
      else if (checkifbyteis(MIDI_Message[0], NOTEOFF) || (checkifbyteis(MIDI_Message[0], NOTEON) && MIDI_Message[2] == 0)){
				voice_index = handleNoteOff(voice_table, voice_index, MIDI_Message[1]);
      }
			else if(checkifbyteis(MIDI_Message[0], CC)){
				handleCC(MIDI_Message[1], MIDI_Message[2]);
      }
		}
	}
}


uint8_t handleNoteOn(struct voice * voice_table, uint8_t voice_index, uint8_t midi_note, uint8_t velocity) {
  //MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN0);
  add_note(voice_table, midi_note, voice_index);

  /*SPI_transmit_wrapper(EUSCI_B0_BASE, NOTEON);
  SPI_transmit_wrapper(EUSCI_B0_BASE, voice_index);
  SPI_transmit_wrapper(EUSCI_B0_BASE, midi_note);
  SPI_transmit_wrapper(EUSCI_B0_BASE, velocity);8*/
  //printf("send SPI note on %d\n",voice_index);
  return (voice_index + 1);
}

uint8_t handleNoteOff(struct voice * voice_table, uint8_t voice_index, uint8_t midi_note) {
  //MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN1);
  //uint8_t voice_index = remove_note(voice_table, midi_note);
  remove_note(voice_table, midi_note); //forgo this crappy algorithm for now

  //INSTEAD WE WILL CYCLE VOICES ROUND ROBIN

  /*SPI_transmit_wrapper(EUSCI_B0_BASE, NOTEOFF);
  SPI_transmit_wrapper(EUSCI_B0_BASE, voice_index);*/
  //printf("send SPI note off %d\n",voice_index);
  return(voice_index + 1);
}

void add_note(struct voice * voice_table, uint8_t midi_note, uint8_t voice_index){
  voice_table[voice_index].midi_note = midi_note;
  voice_table[voice_index].note_state = 1;
  printf("adding note %d to index %d\n",midi_note,voice_index);
}

uint8_t remove_note(struct voice * voice_table, uint8_t midi_note){
  int16_t voice_index = find_voice_of_note(voice_table, midi_note);
  printf("removing note %d from index %d\n",midi_note,voice_index);
  if (voice_index != -1){
    voice_table[voice_index].note_state = 0;
    return((uint8_t)voice_index); //return the newly freed voice number
  }
  else{
    return(0);
  }
}

uint8_t find_voice_of_note(struct voice * voice_table, uint8_t note){
  int16_t i;
  for (i = 0; i < NUMBER_OF_VOICES; i++){
    if (voice_table[i].midi_note == note && voice_table[i].note_state == 1){
      //printf("found note %d in index %d\n", note, i);
      return (i);
    }
  }
  printf("could not find note in array\n");
  return(1);
}

void handleCC(uint8_t cc, uint8_t value){
	switch (cc){
		case ATTACK_CC:
			break;
		case DECAY_CC:

			break;
		case SUSTAIN_CC:

			break;
		case RELEASE_CC:

			break;
		case FILTER_CC:

			break;
	}
}

uint8_t checkifbyteis(uint8_t byte, uint8_t check){
  return ((byte >> 4) == (check >> 4)); //lower bits are the midi channel number. ignore them for now
  //return (byte == check);
}

int main(){
  uint8_t MIDI_Message_NOTEON_30[3] = {NOTEON, 30, 20};
  uint8_t MIDI_Message_NOTEOFF_30[3] = {NOTEOFF, 30, 20};
  uint8_t MIDI_Message_NOTEON_100[3] = {NOTEON, 100, 20};
  uint8_t MIDI_Message_NOTEOFF_100[3] = {NOTEOFF, 100, 20};

  int i;
  for (i=0;i<256;i++){
    parseMidi(MIDI_Message_NOTEON_30);
    parseMidi(MIDI_Message_NOTEON_100);
    parseMidi(MIDI_Message_NOTEOFF_30);
    parseMidi(MIDI_Message_NOTEOFF_100);
  }
}
