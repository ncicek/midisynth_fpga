/* DriverLib Includes */
#include <ti/devices/msp432p4xx/driverlib/driverlib.h>

/* Standard Includes */
#include <stdint.h>
#include <stdbool.h>


const eUSCI_UART_Config uartConfig =
{
  EUSCI_A_UART_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
  96,                                      // BRDIV = 13
  0,                                       // UCxBRF = 0
  0,                                      // UCxBRS = 37
  EUSCI_A_UART_NO_PARITY,                  // No Parity
  EUSCI_A_UART_MSB_FIRST,                  // MSB First
  EUSCI_A_UART_ONE_STOP_BIT,               // One stop bit
  EUSCI_A_UART_MODE,                       // UART mode
  EUSCI_A_UART_OVERSAMPLING_BAUDRATE_GENERATION  // Oversampling
};

const eUSCI_SPI_MasterConfig spiMasterConfig =
{
  EUSCI_B_SPI_CLOCKSOURCE_SMCLK,             // SMCLK Clock Source
  48000000,                                   // SMCLK = DCO = 48MHZ
  1000000,                                    // SPICLK = 1000khz
  EUSCI_B_SPI_MSB_FIRST,                     // MSB First
  EUSCI_B_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT,    // Phase
  EUSCI_B_SPI_CLOCKPOLARITY_INACTIVITY_HIGH, // High polarity
  EUSCI_B_SPI_3PIN                           // 3Wire SPI Mode
};




int main(void)
{
  MAP_WDT_A_holdTimer();

  //MIDI UART
  MAP_GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P1, GPIO_PIN2, GPIO_PRIMARY_MODULE_FUNCTION);  //1.2 is in uart mode
  MAP_UART_initModule(EUSCI_A0_BASE, &uartConfig);
  MAP_UART_enableModule(EUSCI_A0_BASE);
  MAP_UART_enableInterrupt(EUSCI_A0_BASE, EUSCI_A_UART_RECEIVE_INTERRUPT);
  MAP_Interrupt_enableInterrupt(INT_EUSCIA0);

  //SPI
  MAP_GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P1,GPIO_PIN5 | GPIO_PIN6 | GPIO_PIN7, GPIO_PRIMARY_MODULE_FUNCTION);
  MAP_SPI_initMaster(EUSCI_B0_BASE, &spiMasterConfig);
  MAP_SPI_enableModule(EUSCI_B0_BASE);
  MAP_SPI_enableInterrupt(EUSCI_B0_BASE, EUSCI_B_SPI_RECEIVE_INTERRUPT);
  MAP_Interrupt_enableInterrupt(INT_EUSCIB0);

  //MAP_Interrupt_enableSleepOnIsrExit();



}

//ISR for MIDI UARt. Constructs a 3 byte MIDI message and calls MidiParser
void EUSCIA0_IRQHandler(void)
{
  static uint8_t lastStatusByte;
  static uint8_t byteNumber = 0;  //tracks which of the 3 midi bytes we are processing
  static uint8_t MIDI_Message[3] = { 0 };
  uint32_t status = MAP_UART_getEnabledInterruptStatus(EUSCI_A0_BASE);

  MAP_UART_clearInterruptFlag(EUSCI_A0_BASE, status);

  if(status & EUSCI_A_UART_RECEIVE_INTERRUPT_FLAG){
    recievedByte = MAP_UART_receiveData(EUSCI_A0_BASE);

    //Check if in "running status" mode
		//reset bytecounter upon recieving any command byte
		if (recievedByte & (1<<8) == 1) { //check if this is a status byte
			lastStatusByte = recievedByte; //we must store it for "running status"
			byteNumber = 0;
		}
		else {  //if its not a status code
			MIDI_Message[0] = lastStatusByte;
			byteNumber++;	//skip the first byte handler
			MIDI_Message[byteNumber] = recievedByte;
		}

		if (byteNumber >= 2) {
			parseMidi(MIDI_Message);
			byteNumber = 0;
		}
    //MAP_Interrupt_disableSleepOnIsrExit();
  }
}
