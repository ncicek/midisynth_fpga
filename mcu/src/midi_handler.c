#include<stdio.h>
#include<stdint.h>

#include <ti/devices/msp432p4xx/driverlib/driverlib.h>

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
	if (MIDI_Message[0] == NOTEON || MIDI_Message[0] == NOTEOFF || MIDI_Message[0]==CC ){
		if (MIDI_Message[1] & (1<<8) == 0 || MIDI_Message[2] & (1<<8) == 0){  //8th bit of valid data bytes should always be 0
			if (MIDI_Message[0] == NOTEON && MIDI_Message[2] > 0){
        voice_index = handleNoteOn(voice_table, voice_index, MIDI_Message[1], MIDI_Message[2]);
      }
      else if (MIDI_Message[0] == NOTEOFF||(MIDI_Message[0] == NOTEON && MIDI_Message[2] == 0)){
				voice_index = handleNoteOff(voice_table,MIDI_Message[1]);
      }
			else if(MIDI_Message[0] == CC){
				handleCC(MIDI_Message[1], MIDI_Message[2]);
      }
		}
	}
}


uint8_t handleNoteOn(struct voice voice_table[NUMBER_OF_VOICES], uint8_t voice_index, uint8_t midi_note, uint8_t velocity) {
  MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN0);
  add_note(voice_table, midi_note, voice_index);
  MAP_SPI_transmitData(EUSCI_B0_BASE, NOTEON);
  MAP_SPI_transmitData(EUSCI_B0_BASE, voice_index);
  MAP_SPI_transmitData(EUSCI_B0_BASE, midi_note);
  MAP_SPI_transmitData(EUSCI_B0_BASE, velocity);
  return (voice_index++);
}

uint8_t handleNoteOff(struct voice voice_table[NUMBER_OF_VOICES], uint8_t midi_note) {
  MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN1);
  uint8_t voice_index = remove_note(voice_table, midi_note);
  MAP_SPI_transmitData(EUSCI_B0_BASE, NOTEOFF);
  MAP_SPI_transmitData(EUSCI_B0_BASE, voice_index);
  MAP_SPI_transmitData(EUSCI_B0_BASE, midi_note);
  return(voice_index);
}

void add_note(struct voice voice_table[NUMBER_OF_VOICES], uint8_t midi_note, uint8_t voice_index){
  voice_table[voice_index].midi_note = midi_note;
  voice_table[voice_index].note_state = 1;
}

uint8_t remove_note(struct voice voice_table[NUMBER_OF_VOICES], uint8_t midi_note){
  int16_t voice_index = find_voice_of_note(voice_table, midi_note);

  if (voice_index != -1){
    voice_table[voice_index].note_state = 0;
    return((uint8_t)voice_index); //return the newly freed voice number
  }
  else{
    return(0);
  }
}

uint8_t find_voice_of_note(struct voice voice_table[NUMBER_OF_VOICES], uint8_t note){
  int16_t i;
  for (i = 0; i < NUMBER_OF_VOICES; i++){
    if (voice_table[i].midi_note == note && voice_table[i].note_state == 1){
      return (i);
    }
  }
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
