#ifndef midi_handler_h
#define midi_handler_h

#define NUMBER_OF_VOICES 256

struct voice;

void parseMidi(uint8_t MIDI_Message[]);
uint8_t handleNoteOn(struct voice * voice_table, uint8_t voice_index, uint8_t midi_note, uint8_t velocity);
uint8_t handleNoteOff(struct voice * voice_table, uint8_t voice_index, uint8_t midi_note);
void add_note(struct voice * voice_table, uint8_t midi_note, uint8_t voice_index);
uint8_t remove_note(struct voice * voice_table, uint8_t midi_note);
uint8_t find_voice_of_note(struct voice * voice_table, uint8_t note);
void handleCC(uint8_t cc, uint8_t value);
uint8_t checkifbyteis (uint8_t byte, uint8_t check);
void SPI_transmit_wrapper(uint32_t moduleInstance, uint_fast8_t transmitData);
uint32_t float_to_fixedpoint(float64_t float_coeff, uint8_t bits);
float64_t calcCoef(rate, targetRatio);




#endif
