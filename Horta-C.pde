#include <WaspXBee900HP.h>
#include <WaspFrame.h>
#include <WaspSensorAgr_v30.h>

// Destination MAC address
//////////////////////////////////////////
char RX_ADDRESS[] = "0013A200414847A0";
//////////////////////////////////////////

// Define the Waspmote ID
char WASPMOTE_ID[] = "Horta-C";

// define variable
uint8_t error;

//------------------------------------------------
float lwSensorr;
leafWetnessClass lwSensor;
//------------------------------------------------
float ds18b202 = 0;
ds18b20Class ds18b20;
//------------------------------------------------
uint32_t luxes = 0;
//------------------------------------------------
float anemometer;
float pluviometer1;
float pluviometer2;
float pluviometer3;
int vane;
int pendingPulses;
weatherStationClass weather;
//------------------------------------------------
uint8_t  panID[2] = {0x11,0x11};
uint8_t  channel = 0x17;
//------------------------------------------------

void setup()

{
  //Turn On Agriculture Sensors
  Agriculture.ON();
  // init USB port
  USB.ON();
  USB.println(F("Sending packets example"));

  //---------
  RTC.ON();
  //---------

  // store Waspmote identifier in EEPROM memory
  frame.setID( WASPMOTE_ID );

  // init XBee
  xbee900HP.ON();

  //---------------------------------------
  xbee900HP.setPAN( panID );

  // check the AT commmand execution flag
  if( xbee900HP.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbee900HP.PAN_ID[0] ); 
    USB.printHex( xbee900HP.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }
  //----------------------------------------------
  xbee900HP.setChannel( channel );

  // check at commmand execution flag
  if( xbee900HP.error_AT == 0 ) 
  {
    USB.print(F("1. Channel set OK to: 0x"));
    USB.printHex( xbee900HP.channel );
    USB.println();
  }
  else 
  {
    USB.println(F("1. Error calling 'setChannel()'"));
  }

  //------------------------------------------------
}


void loop()
{

Agriculture.ON();
xbee900HP.ON();
//------------------------------------------------
lwSensorr = lwSensor.getLeafWetness();
USB.print(lwSensorr);
//------------------------------------------------
ds18b202 = ds18b20.readDS18b20();
USB.print(ds18b202);
//------------------------------------------------
luxes = Agriculture.getLuxes(INDOOR); 
USB.print(luxes);
//------------------------------------------------

//------------------------------------------------
//------------------------------------------------
enableInterrupts(PLV_INT);
//------------------------------------------------
if( intFlag & PLV_INT)
  {
    USB.println(F("+++ PLV interruption +++"));

    pendingPulses = intArray[PLV_POS];

    USB.print(F("Number of pending pulses:"));
    USB.println( pendingPulses );

    for(int i=0 ; i<pendingPulses; i++)
    {
      // Enter pulse information inside class structure
      weather.storePulse();

      // decrease number of pulses
      intArray[PLV_POS]--;
    }
  }

  anemometer = weather.readAnemometer();
  pluviometer1 = weather.readPluviometerCurrent();
  pluviometer2 = weather.readPluviometerHour();
  pluviometer3 = weather.readPluviometerDay();
  
  USB.println( pluviometer1 );
  USB.println( pluviometer2 );
  USB.println( pluviometer3 );
  USB.print(anemometer);
  
  
  char vane_str[10] = {0};
  switch(weather.readVaneDirection())
  {
  case  SENS_AGR_VANE_N   :  snprintf( vane_str, sizeof(vane_str), "N" );
                             break;
  case  SENS_AGR_VANE_NNE :  snprintf( vane_str, sizeof(vane_str), "NNE" );
                             break;  
  case  SENS_AGR_VANE_NE  :  snprintf( vane_str, sizeof(vane_str), "NE" );
                             break;    
  case  SENS_AGR_VANE_ENE :  snprintf( vane_str, sizeof(vane_str), "ENE" );
                             break;      
  case  SENS_AGR_VANE_E   :  snprintf( vane_str, sizeof(vane_str), "E" );
                             break;    
  case  SENS_AGR_VANE_ESE :  snprintf( vane_str, sizeof(vane_str), "ESE" );
                             break;  
  case  SENS_AGR_VANE_SE  :  snprintf( vane_str, sizeof(vane_str), "SE" );
                             break;    
  case  SENS_AGR_VANE_SSE :  snprintf( vane_str, sizeof(vane_str), "SSE" );
                             break;   
  case  SENS_AGR_VANE_S   :  snprintf( vane_str, sizeof(vane_str), "S" );
                             break; 
  case  SENS_AGR_VANE_SSW :  snprintf( vane_str, sizeof(vane_str), "SSW" );
                             break; 
  case  SENS_AGR_VANE_SW  :  snprintf( vane_str, sizeof(vane_str), "SW" );
                             break;  
  case  SENS_AGR_VANE_WSW :  snprintf( vane_str, sizeof(vane_str), "WSW" );
                             break; 
  case  SENS_AGR_VANE_W   :  snprintf( vane_str, sizeof(vane_str), "W" );
                             break;   
  case  SENS_AGR_VANE_WNW :  snprintf( vane_str, sizeof(vane_str), "WNW" );
                             break; 
  case  SENS_AGR_VANE_NW  :  snprintf( vane_str, sizeof(vane_str), "WN" );
                             break;
  case  SENS_AGR_VANE_NNW :  snprintf( vane_str, sizeof(vane_str), "NNW" );
                             break;  
  default                 :  snprintf( vane_str, sizeof(vane_str), "error" );
                             break;    
  }

  USB.println( vane_str );
//------------------------------------------------
//------------------------------------------------



  frame.createFrame(ASCII);  
  
  // add frame fields
  frame.addSensor(SENSOR_AGR_LW,lwSensorr);
  frame.addSensor(SENSOR_AGR_SOILTC,ds18b202);
  frame.addSensor(SENSOR_AGR_LUXES,luxes);
  frame.addSensor(SENSOR_AGR_PLV1,pluviometer1);
  frame.addSensor(SENSOR_AGR_PLV2,pluviometer2);
  frame.addSensor(SENSOR_AGR_PLV3,pluviometer3);
  frame.addSensor(SENSOR_AGR_ANE,anemometer);
  frame.addSensor(SENSOR_STR, vane_str);
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  
  // show frame to send
  frame.showFrame();


  ///////////////////////////////////////////
  // 2. Send packet
  ///////////////////////////////////////////  

  // send XBee packet
  error = xbee900HP.send( RX_ADDRESS, frame.buffer, frame.length );   
  
  // check TX flag
  if( error == 0 )
  {
    USB.println(F("send ok"));
    
    // blink green LED
    Utils.blinkGreenLED();
    
  }
  else 
  {
    USB.println(F("send error"));
    
    // blink red LED
    Utils.blinkRedLED();  
  }
  
  // wait for five seconds
  xbee900HP.sleep();
  delay(20000);
  PWR.deepSleep("00:00:00:30",RTC_OFFSET,RTC_ALM1_MODE1,ALL_OFF);
}



