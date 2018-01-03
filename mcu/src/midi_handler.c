#include<stdio.h>
#include<stdint.h>
#include <math.h>
#include <ti/devices/msp432p4xx/driverlib/driverlib.h>


#include "midi_handler.h"

#define RATE 24E6/256/3

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
  MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN0);
  add_note(voice_table, midi_note, voice_index);

  SPI_transmit_wrapper(EUSCI_B0_BASE, NOTEON);
  SPI_transmit_wrapper(EUSCI_B0_BASE, voice_index);
  SPI_transmit_wrapper(EUSCI_B0_BASE, midi_note);
  SPI_transmit_wrapper(EUSCI_B0_BASE, velocity);
  voice_index = voice_index + 1;
  return (voice_index);
}

uint8_t handleNoteOff(struct voice * voice_table, uint8_t voice_index, uint8_t midi_note) {
  MAP_GPIO_toggleOutputOnPin(GPIO_PORT_P2, GPIO_PIN1);
  uint8_t voice_index_to_be_removed = remove_note(voice_table, midi_note);  //skip this algorithm
  //INSTEAD WE CYCLE VOICES IN ROUND ROBIN FASHION
  remove_note(voice_table, midi_note);

  SPI_transmit_wrapper(EUSCI_B0_BASE, NOTEOFF);
  SPI_transmit_wrapper(EUSCI_B0_BASE, voice_index_to_be_removed);
  voice_index = voice_index + 1;  //round robin
  return(voice_index);
}

void add_note(struct voice * voice_table, uint8_t midi_note, uint8_t voice_index){
  voice_table[voice_index].midi_note = midi_note;
  voice_table[voice_index].note_state = 1;
}

uint8_t remove_note(struct voice * voice_table, uint8_t midi_note){
  int16_t voice_index = find_voice_of_note(voice_table, midi_note);

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
      return (i);
    }
  }
  return(1);
}

void handleCC(uint8_t cc, uint8_t value){
	switch (cc){
		case ATTACK_CC:
      float64_t targetRatioA = (float64_t)value/(2^7);  //scale to 0-1.0
      uint32_t attackCoef = float_to_fixedpoint( calcCoef(RATE,targetRatioA) ,24);
      uint32_t attackBase = float_to_fixedpoint( (1.0 + targetRatioA) * (1.0 - attackCoef) ,24);

      SPI_transmit_wrapper(EUSCI_B0_BASE, CC);
      SPI_transmit_wrapper(EUSCI_B0_BASE, ATTACK_CC);
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

uint32_t float_to_fixedpoint(float64_t float_coeff, uint8_t bits){
  return((uint32_t)(round(float_coeff * 2**bits)))
}

float64_t calcCoef(rate, targetRatio){
	return (exp(-log((1.0 + targetRatio) / targetRatio) / rate))
}

uint8_t checkifbyteis(uint8_t byte, uint8_t check){
  return ((byte >> 4) == (check >> 4)); //lower bits are the midi channel number. ignore them for now
  //return (byte == check);
}

void SPI_transmit_wrapper(uint32_t moduleInstance, uint_fast8_t transmitData){
  while((EUSCI_B0->IFG >>1) == 0);  //wait until tx is free
  MAP_SPI_transmitData(moduleInstance, transmitData);
}
