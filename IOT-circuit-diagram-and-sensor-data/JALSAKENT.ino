
  #include <WiFi.h>
  #include <WiFiClientSecure.h>
  #include <HTTPClient.h>
  #include <OneWire.h>
  #include <DallasTemperature.h>
  #include <math.h>
  #include <time.h>
  #include <ArduinoJson.h>
  #include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);


  // WiFi credentials
  #define WIFI_SSID "AD01"
  #define WIFI_PASSWORD "1111111111"

  // Sensor pins
  #define ONE_WIRE_BUS 4
  #define TDS_PIN 34
  #define TURBIDITY_PIN 35
  #define MOTOR_PIN 2
  #define BUZZER_PIN 25
  
  unsigned long lastLCDUpdate = 0;
const unsigned long LCD_INTERVAL = 2000;

int lcdScreen = 0;

bool temperatureAlert = false;
bool tdsAlert = false;
bool turbidityAlert = false;

#define TDS_THRESHOLD 500.0

const char* commandURL =
"https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com/CHLORINATION_COMMAND.json";

const char* statusURL =
"https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com/CHLORINATION_STATUS.json";

unsigned long lastCommandCheck = 0;
const unsigned long COMMAND_INTERVAL = 1000;

String lastCommandId = "";

bool motorRunning = false;
unsigned long motorStartTime = 0;
unsigned long motorDuration = 0;

float DOSE_TIME_PER_ML_MS = 1000.0; // Example only; calibrate with water

  // Firebase URLs
  const char* liveURL = 
  "https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com/SENSOR_DATA.json";

  const char* historyURL =
  "https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com/SENSOR_HISTORY.json";


  // Indian Standard Time (IST)
  const char* NTP_SERVER = "pool.ntp.org";
  const long GMT_OFFSET_SEC = 19800;
  const int DAYLIGHT_OFFSET_SEC = 0;

  // Experimental turbidity calibration
const float CLEAR_END_V = 1.498;
const float MUDDY_END_V = 0.318;
const float MUDDY_END_NTU = 1000.0;

  // DS18B20 setup
  OneWire oneWire(ONE_WIRE_BUS);
  DallasTemperature sensors(&oneWire);

  unsigned long previousMillis = 0;
  const unsigned long interval = 3000;

  // Read average analog voltage
  float readVoltage(int pin) {
    uint32_t sum = 0;

    for (int i = 0; i < 30; i++) {
      sum += analogReadMilliVolts(pin);
      delay(10);
    }

    return (sum / 30.0) / 1000.0;
  }

  // Read TDS in estimated ppm

  #define TDS_SAMPLES 30

float getMedianVoltage(int pin)
{
  float samples[TDS_SAMPLES];

  for (int i = 0; i < TDS_SAMPLES; i++)
  {
    samples[i] = analogReadMilliVolts(pin) / 1000.0;
    delay(40);
  }

  // Sort readings in ascending order
  for (int i = 0; i < TDS_SAMPLES - 1; i++)
  {
    for (int j = 0; j < TDS_SAMPLES - i - 1; j++)
    {
      if (samples[j] > samples[j + 1])
      {
        float temp = samples[j];
        samples[j] = samples[j + 1];
        samples[j + 1] = temp;
      }
    }
  }

  // Return median voltage
  return (samples[14] + samples[15]) / 2.0;
}

  float readTDS(float temperature)
{
  float voltage = getMedianVoltage(TDS_PIN);

  float compensationCoefficient =
    1.0 + 0.02 * (temperature - 25.0);

  float compensatedVoltage =
    voltage / compensationCoefficient;

  float tdsValue =
    (133.42 * pow(compensatedVoltage, 3)
    - 255.86 * pow(compensatedVoltage, 2)
    + 857.39 * compensatedVoltage) * 0.5;

  if (tdsValue < 0)
    tdsValue = 0;

  Serial.print("TDS Voltage: ");
  Serial.print(voltage, 3);

  Serial.print(" V | TDS: ");
  Serial.print(tdsValue, 1);
  Serial.println(" ppm");

  return tdsValue;
}

  // Read turbidity sensor voltage
 float turbidityVoltage = 0.0;
float estimatedNTU = 0.0;

float readTurbidity() {

  turbidityVoltage = readVoltage(TURBIDITY_PIN);

  estimatedNTU =
    (CLEAR_END_V - turbidityVoltage) /
    (CLEAR_END_V - MUDDY_END_V) *
    MUDDY_END_NTU;

  estimatedNTU = constrain(estimatedNTU, 0, MUDDY_END_NTU);

  Serial.print("Turbidity Voltage: ");
  Serial.print(turbidityVoltage, 3);

  Serial.print(" V | Experimental NTU Estimate: ");
  Serial.println(estimatedNTU, 1);

  return estimatedNTU;
}

 void connectWiFi()
{
  showLCDMessage("JalSanket", "Connecting WiFi");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected!");
  Serial.println(WiFi.localIP());

  showLCDMessage("WiFi Connected!", "System Ready");
  delay(1500);
}

  // Synchronize ESP32 time with NTP server
  void initializeTime() {
    configTime(
      GMT_OFFSET_SEC,
      DAYLIGHT_OFFSET_SEC,
      NTP_SERVER
    );

    Serial.println("Synchronizing time...");

    struct tm timeInfo;

    if (getLocalTime(&timeInfo, 15000)) {
      Serial.println("Time synchronized!");
      Serial.println(&timeInfo, "%d-%m-%Y %H:%M:%S");
    } else {
      Serial.println("Time synchronization failed!");
    }
  }

  // Get current Unix timestamp in milliseconds
  unsigned long long getCurrentTimestamp() {
    time_t now;
    time(&now);

    if (now < 1700000000) {
      return 0;
    }

    return (unsigned long long)now * 1000ULL;
  }
  // Upload sensor data to Firebase
 void uploadData(float temperature, float tds, float turbidity)
{
  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient https;

  unsigned long heartbeat = millis();
  unsigned long long currentTimestamp = getCurrentTimestamp();

  // Current sensor readings
  String jsonData = "{";

  jsonData += "\"Temperature\":" + String(temperature, 2) + ",";
  jsonData += "\"TDS\":" + String(tds, 2) + ",";
  jsonData += "\"Turbidity\":" + String(turbidity, 1) + ",";
  jsonData += "\"TurbidityVoltage\":" + String(turbidityVoltage, 3) + ",";
  jsonData += "\"TurbidityNTU_Estimate\":" + String(estimatedNTU, 1) + ",";
  jsonData += "\"Heartbeat\":" + String(heartbeat);

  jsonData += "}";

  // Upload latest readings
  if (https.begin(client, liveURL))
  {
    https.addHeader("Content-Type", "application/json");

    int liveCode = https.PUT(jsonData);

    Serial.print("Live Data HTTP Code: ");
    Serial.println(liveCode);

    https.end();
  }

  // Create history record
  String historyData = "{";

  historyData += "\"Temperature\":" + String(temperature, 2) + ",";
  historyData += "\"TDS\":" + String(tds, 2) + ",";
  historyData += "\"Turbidity\":" + String(turbidity, 1) + ",";
  historyData += "\"TurbidityVoltage\":" + String(turbidityVoltage, 3) + ",";
  historyData += "\"TurbidityNTU_Estimate\":" + String(estimatedNTU, 1) + ",";
  historyData += "\"Timestamp\":" + String(currentTimestamp);

  historyData += "}";

  if (https.begin(client, historyURL))
  {
    https.addHeader("Content-Type", "application/json");

    int historyCode = https.POST(historyData);

    Serial.print("History HTTP Code: ");
    Serial.println(historyCode);

    https.end();
  }
}

  void updateChlorinationStatus(
  String state,
  String message,
  String testId,
  float doseMl
) {
  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient https;

  StaticJsonDocument<256> doc;
  doc["state"] = state;
  doc["message"] = message;
  doc["testId"] = testId;
  doc["doseMl"] = doseMl;

  String json;
  serializeJson(doc, json);

  if (https.begin(client, statusURL)) {
    https.addHeader("Content-Type", "application/json");
    https.PUT(json);
    https.end();
  }
}

void checkDosingCommand() {
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient https;

  if (!https.begin(client, commandURL)) return;

  int httpCode = https.GET();

  if (httpCode == HTTP_CODE_OK) {
    String payload = https.getString();

    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, payload);

    if (!error) {
      String commandId = doc["id"] | "";
      String action = doc["action"] | "";
      String testId = doc["testId"] | "";
      float doseMl = doc["doseMl"] | 0.0;

      if (commandId.length() > 0 && commandId != lastCommandId) {

        lastCommandId = commandId;

        if (action == "EMERGENCY_STOP") {
          motorRunning = false;
          digitalWrite(MOTOR_PIN, LOW);

          updateChlorinationStatus(
            "STANDBY", "Emergency stop activated", testId, doseMl
          );
        }

        else if (action == "START" && !motorRunning && doseMl > 0) {

          motorDuration = (unsigned long)
                          (doseMl * DOSE_TIME_PER_ML_MS);

          motorStartTime = millis();
          motorRunning = true;

          digitalWrite(MOTOR_PIN, HIGH);

          updateChlorinationStatus(
            "SIMULATION_RUNNING",
            "Dosing motor activated",
            testId,
            doseMl
          );
        }
      }
    }
  }

  https.end();
}

void controlDosingMotor() {
  if (motorRunning &&
      millis() - motorStartTime >= motorDuration) {

    motorRunning = false;
    digitalWrite(MOTOR_PIN, LOW);

    updateChlorinationStatus(
      "SIMULATION_COMPLETED",
      "Dosing operation completed",
      "",
      0
    );
  }
}
void checkTDSAlarm(float tds)
{
  if (tds >= TDS_THRESHOLD)
  {
    digitalWrite(BUZZER_PIN, HIGH);

    Serial.println("WARNING: TDS LEVEL HIGH!");
    Serial.println("Water Quality Abnormal - Check Water");
  }
  else
  {
    digitalWrite(BUZZER_PIN, LOW);
  }
}

void showLCDMessage(String line1, String line2)
{
  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print(line1);

  lcd.setCursor(0, 1);
  lcd.print(line2);
}

void updateLCD(float temperature, float tds, float turbidity)
{
  // Give warning priority over normal readings
  if (tds >= TDS_THRESHOLD)
  {
    showLCDMessage("!! WARNING !!", "TDS LEVEL HIGH");
    return;
  }

  // Change screen every 2 seconds
  if (millis() - lastLCDUpdate >= LCD_INTERVAL)
  {
    lastLCDUpdate = millis();

    lcdScreen++;
    if (lcdScreen > 2)
      lcdScreen = 0;

    lcd.clear();

    if (lcdScreen == 0)
    {
      lcd.setCursor(0, 0);
      lcd.print("Temperature:");

      lcd.setCursor(0, 1);
      lcd.print(temperature, 1);
      lcd.print((char)223);
      lcd.print("C");
    }
    else if (lcdScreen == 1)
    {
      lcd.setCursor(0, 0);
      lcd.print("TDS Value:");

      lcd.setCursor(0, 1);
      lcd.print(tds, 0);
      lcd.print(" ppm");
    }
    else if (lcdScreen == 2)
    {
      lcd.setCursor(0, 0);
      lcd.print("Turbidity:");

      lcd.setCursor(0, 1);
      lcd.print(turbidity, 1);
      lcd.print(" NTU");
    }
  }
}

void setup()
{
  Serial.begin(115200);

  // Initialize LCD first
  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();

  showLCDMessage("JalSanket", "Starting...");
  delay(1500);

  analogReadResolution(12);

  sensors.begin();
  sensors.setResolution(10);
  sensors.setWaitForConversion(true);

  Serial.print("DS18B20 devices found: ");
  Serial.println(sensors.getDeviceCount());

  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  connectWiFi();

  if (WiFi.status() == WL_CONNECTED)
  {
    initializeTime();
  }
}

  void loop() {
    if (WiFi.status() != WL_CONNECTED) {
      connectWiFi();
    }

    if (millis() - previousMillis >= interval) {
      previousMillis = millis();

  // Read temperature — same method as the working standalone test
// Read temperature
sensors.requestTemperatures();

float temperature = sensors.getTempCByIndex(0);

// Validate temperature
if (temperature == DEVICE_DISCONNECTED_C ||
    temperature == 85.0 ||
    temperature < -55.0 ||
    temperature > 125.0)
{
    Serial.println("DS18B20 read error");
    return;
}

Serial.print("Temperature: ");
Serial.print(temperature);
Serial.println(" °C");

// Read remaining sensors
float tds = readTDS(temperature);
float turbidity = readTurbidity();

// Check TDS threshold and activate buzzer
checkTDSAlarm(tds);

// Update LCD display
updateLCD(temperature, tds, turbidity);

// Check dosing command
if (millis() - lastCommandCheck >= COMMAND_INTERVAL)
{
    lastCommandCheck = millis();
    checkDosingCommand();
}

controlDosingMotor();
      
      

      // Display readings
      Serial.println("\n--- ACTUAL SENSOR READINGS ---");

      Serial.print("Temperature: ");
      Serial.println(temperature);

      Serial.print("TDS: ");
      Serial.println(tds);

Serial.print("Turbidity NTU Estimate: ");
Serial.println(turbidity);

Serial.print("Turbidity Voltage: ");
Serial.println(turbidityVoltage);
      // Upload to Firebase
      uploadData(temperature, tds, turbidity);

      Serial.println("Sensor upload cycle completed");
      Serial.println("------------------------------");
    }
  }
