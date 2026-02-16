#include <HX711.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const int LOADCELL_DOUT_PIN = 4;
const int LOADCELL_SCK_PIN = 5;

const char* apn = "your_apn";
const char* gprsUser = "";
const char* gprsPass = "";

const char* firebaseHost = "YOUR_FIREBASE_PROJECT.firebaseio.com";
const char* firebaseAuth = "YOUR_FIREBASE_AUTH_TOKEN";
const char* machineId = "MACHINE_001";

HX711 scale;

float calibration_factor = 2280.0;
unsigned long lastUpdate = 0;
const unsigned long updateInterval = 2000;

void setup() {
  Serial.begin(115200);
  Serial.println("Fish Market Weighing Scale");
  Serial.println("Initializing...");
  
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare();
  
  Serial.println("Scale initialized");
  Serial.println("Remove all weight from scale");
  Serial.println("After readings begin, place known weight for calibration");
  Serial.println("Press 't' to tare (zero) the scale");
  Serial.println("Press 'c' to calibrate");
  
  initGSM();
}

void loop() {
  if (Serial.available() > 0) {
    char command = Serial.read();
    
    if (command == 't') {
      scale.tare();
      Serial.println("Scale tared");
    } else if (command == 'c') {
      calibrateScale();
    }
  }
  
  unsigned long currentMillis = millis();
  
  if (currentMillis - lastUpdate >= updateInterval) {
    lastUpdate = currentMillis;
    
    float weight = scale.get_units(10);
    
    if (weight < 0) {
      weight = 0;
    }
    
    Serial.print("Weight: ");
    Serial.print(weight, 2);
    Serial.println(" kg");
    
    sendWeightToFirebase(weight);
  }
}

void initGSM() {
  Serial.println("Initializing GSM...");
  
  Serial2.begin(115200);
  
  sendATCommand("AT", 1000);
  sendATCommand("AT+CPIN?", 1000);
  sendATCommand("AT+CREG?", 1000);
  sendATCommand("AT+CGATT?", 1000);
  sendATCommand("AT+CIPSHUT", 1000);
  sendATCommand("AT+CIPSTATUS", 2000);
  sendATCommand("AT+CIPMUX=0", 1000);
  
  String apnCmd = "AT+CSTT=\"" + String(apn) + "\",\"" + String(gprsUser) + "\",\"" + String(gprsPass) + "\"";
  sendATCommand(apnCmd, 1000);
  sendATCommand("AT+CIICR", 3000);
  sendATCommand("AT+CIFSR", 1000);
  
  Serial.println("GSM Initialized");
}

void sendATCommand(String command, int timeout) {
  Serial.println("Sending: " + command);
  Serial2.println(command);
  
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (Serial2.available()) {
      char c = Serial2.read();
      Serial.print(c);
    }
  }
  Serial.println();
}

void sendWeightToFirebase(float weight) {
  String url = "https://" + String(firebaseHost) + "/weighing_machines/" + String(machineId) + ".json?auth=" + String(firebaseAuth);
  
  StaticJsonDocument<200> doc;
  doc["currentWeight"] = weight;
  doc["lastUpdated"][".sv"] = "timestamp";
  doc["machineId"] = machineId;
  doc["status"] = "active";
  doc["calibrationLock"] = true;
  
  String jsonData;
  serializeJson(doc, jsonData);
  
  String httpCmd = "AT+CIPSTART=\"TCP\",\"" + String(firebaseHost) + "\",443";
  sendATCommand(httpCmd, 3000);
  
  String httpRequest = "PATCH " + url + " HTTP/1.1\r\n";
  httpRequest += "Host: " + String(firebaseHost) + "\r\n";
  httpRequest += "Content-Type: application/json\r\n";
  httpRequest += "Content-Length: " + String(jsonData.length()) + "\r\n";
  httpRequest += "Connection: close\r\n\r\n";
  httpRequest += jsonData;
  
  sendATCommand("AT+CIPSEND=" + String(httpRequest.length()), 2000);
  sendATCommand(httpRequest, 3000);
  sendATCommand("AT+CIPCLOSE", 1000);
  
  Serial.println("Weight sent to Firebase: " + String(weight) + " kg");
}

void calibrateScale() {
  Serial.println("Calibration mode");
  Serial.println("Remove all weight from scale");
  delay(3000);
  
  scale.tare();
  Serial.println("Place known weight on scale");
  Serial.println("Enter weight in kg:");
  
  while (!Serial.available()) {
    delay(100);
  }
  
  float knownWeight = Serial.parseFloat();
  
  Serial.println("Reading scale...");
  delay(2000);
  
  float reading = scale.get_units(10);
  
  if (reading != 0) {
    calibration_factor = reading / knownWeight;
    scale.set_scale(calibration_factor);
    
    Serial.print("New calibration factor: ");
    Serial.println(calibration_factor);
    Serial.println("Calibration complete!");
  } else {
    Serial.println("Calibration failed - no reading");
  }
}
