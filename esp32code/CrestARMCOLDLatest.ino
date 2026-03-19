#include <Wire.h>
#include <Adafruit_SHT31.h>
#include <TinyGPSPlus.h>
#include "FS.h"
#include "SD.h"
#include <SPI.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>


// --- I2C PINS ---
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22


// --- SD CARD SPI PINS ---
#define SD_SCK  18
#define SD_MISO 19
#define SD_MOSI 23
#define SD_CS   5


// --- GPS UART PINS ---
#define GPS_RX 16
#define GPS_TX 17


// --- Objects ---
Adafruit_SHT31 sht31 = Adafruit_SHT31();
TinyGPSPlus gps;

// BLE setup
BLEServer* pServer = NULL;
BLECharacteristic* pTempCharacteristic;
BLECharacteristic* pHumCharacteristic;
BLECharacteristic* pGPSCharacteristic;
BLECharacteristic *pLatCharacteristic;
BLECharacteristic *pLngCharacteristic;
BLECharacteristic *pAltCharacteristic;
BLECharacteristic *pSpdCharacteristic;
BLECharacteristic *pSatCharacteristic;
// Custom UUIDs (you can generate your own at https://www.uuidgenerator.net/)

#define SERVICE_UUID           "12345678-1234-1234-1234-1234567890ab"
#define TEMP_CHARACTERISTIC_UUID "12345678-1234-1234-1234-1234567890ac"
#define HUM_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890ad"
#define LAT_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890ae"
#define LNG_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890af"
#define ALT_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890ag"
#define SPD_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890ah"
#define SAT_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-1234567890ai"

class MyServerCallbacks : public BLEServerCallbacks {

  void onConnect(BLEServer* pServer) {
    Serial.println("BLE client connected!");
  }

  void onDisconnect(BLEServer* pServer) {
    Serial.println("BLE client disconnected!");
  }
};

// --- Function to append data to SD card ---
void appendFile(fs::FS &fs, const char *path, const char *message) {
  File file = fs.open(path, FILE_APPEND);
  if (!file) {
    Serial.println("File failed to open for appending.");
    return;
  }
  if (file.print(message)) {
    Serial.print("Data logged: ");
    Serial.println(message);
  } else {
    Serial.println("Append failed.");
  }
  file.close();
}


// --- Setup ---
void setup() {
  Serial.begin(115200);
  Serial.println("\n--- ESP32: Temp, Humidity, GPS, SD Logging ---");


  // --- Initialize I2C & Sensor ---
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  if (!sht31.begin(0x44)) {
    Serial.println("SHT31 not found! Check wiring.");
    while (1) delay(100);
  }
  sht31.heater(false);
  Serial.println("SHT31 initialized.");

  // Initialize BLE
  BLEDevice::init("ESP32_SHT3X"); // Name shown in nRF app
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create characteristics for temp and humidity
  pTempCharacteristic = pService->createCharacteristic(
                          TEMP_CHARACTERISTIC_UUID,
                          BLECharacteristic::PROPERTY_READ |
                          BLECharacteristic::PROPERTY_NOTIFY
                        );


  pHumCharacteristic = pService->createCharacteristic(
                         HUM_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );

  
  pLatCharacteristic = pService->createCharacteristic(
                         LAT_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );


  pLngCharacteristic = pService->createCharacteristic(
                         LNG_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );


  pAltCharacteristic = pService->createCharacteristic(
                         ALT_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );


  pSpdCharacteristic = pService->createCharacteristic(
                         SPD_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );


  pSatCharacteristic = pService->createCharacteristic(
                         SAT_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_READ |
                         BLECharacteristic::PROPERTY_NOTIFY

                       );

  // Start service
  pService->start();
  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
  Serial.println("BLE device is now advertising...");

  // --- Initialize SD Card ---
  SPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  if (!SD.begin(SD_CS)) {
    Serial.println("SD Card Mount Failed!");
  } else {
    Serial.println("SD Card initialized.");
    if (!SD.exists("/data.csv")) {
      appendFile(SD, "/data.csv", "Time(min),Temp(C),Humidity(%),Latitude,Longitude,Altitude(m),Speed(km/h),Satellites\n");
    }
  }


  // --- Initialize GPS ---
  Serial2.begin(9600, SERIAL_8N1, GPS_RX, GPS_TX);
  Serial.println("Waiting for GPS fix...");
}


// --- Main Loop ---
void loop() {
  // --- Update GPS ---
  while (Serial2.available() > 0) {
    gps.encode(Serial2.read());
  }


  // --- Read Sensor Data ---
  float temperatureC = sht31.readTemperature();
  float humidity = sht31.readHumidity();
  unsigned long currentTime = millis();
  float minutes = currentTime / 60000.0;


  // --- GPS Data ---
  double lat = gps.location.lat();
  double lng = gps.location.lng();
  double alt = gps.altitude.meters();
  double spd = gps.speed.kmph();
  int sats = gps.satellites.value();


  // --- Only log if data is valid ---
  if (!isnan(temperatureC) && !isnan(humidity)) {
    String dataMessage = "";
    dataMessage += String(minutes, 2) + ",";
    dataMessage += String(temperatureC, 2) + ",";
    dataMessage += String(humidity, 2) + ",";
    dataMessage += (gps.location.isValid() ? String(lat, 6) : "N/A");
    dataMessage += ",";
    dataMessage += (gps.location.isValid() ? String(lng, 6) : "N/A");
    dataMessage += ",";
    dataMessage += (gps.altitude.isValid() ? String(alt, 2) : "N/A");
    dataMessage += ",";
    dataMessage += (gps.speed.isValid() ? String(spd, 2) : "N/A");
    dataMessage += ",";
    dataMessage += (gps.satellites.isValid() ? String(sats) : "N/A");
    dataMessage += "\n";


    // --- Log to SD ---
    if (SD.cardType() != CARD_NONE) {
      appendFile(SD, "/data.csv", dataMessage.c_str());
    }

    // --- BLE Send ---
    char temperatureStr[8];
    char humidityStr[8];
    char latStr[16];
    char lngStr[16];
    char altStr[8];
    char spdStr[8];
    char satStr[8];

    // Convert floats to strings
    dtostrf(temperatureC, 4, 2, temperatureStr);
    dtostrf(humidity, 4, 2, humidityStr);
    dtostrf(lat, 10, 6, latStr);
    dtostrf(lng, 10, 6, lngStr);
    dtostrf(alt, 6, 2, altStr);
    dtostrf(spd, 6, 2, spdStr);
    sprintf(satStr, "%d", sats); // satellites are integers

    // Send BLE notifications
    pTempCharacteristic->setValue(temperatureStr);
    pTempCharacteristic->notify();

    pHumCharacteristic->setValue(humidityStr);
    pHumCharacteristic->notify();

    if (gps.location.isValid()) {
      pLatCharacteristic->setValue(latStr);
      pLatCharacteristic->notify();

      pLngCharacteristic->setValue(lngStr);
      pLngCharacteristic->notify();

      pAltCharacteristic->setValue(altStr);
      pAltCharacteristic->notify();

      pSpdCharacteristic->setValue(spdStr);
      pSpdCharacteristic->notify();

      pSatCharacteristic->setValue(satStr);
      pSatCharacteristic->notify();
    }


    // --- Serial Output ---
    Serial.println("------------------------------------------------");
    Serial.printf("Time: %.2f min\n", minutes);
    Serial.printf("Temp: %.2f °C | Humidity: %.2f %%\n", temperatureC, humidity);


    if (gps.location.isValid()) {
      Serial.printf("Lat: %.6f | Lng: %.6f\n", lat, lng);
      Serial.printf("Alt: %.2f m | Speed: %.2f km/h | Sats: %d\n", alt, spd, sats);
    } else {
      Serial.println("GPS: No valid fix yet.");
    }
  } else {
    Serial.println("Error reading SHT31 sensor.");
  }
  // --- Debug: Show if GPS data is being received ---
  Serial.print("GPS chars processed: ");
  Serial.println(gps.charsProcessed());




  delay(6000); // Log every 1 minute
}



