# JalSanket – IoT-Based Water Quality Monitoring System

JalSanket is an IoT-based water quality monitoring system designed to monitor important water parameters and display the collected data through a web dashboard.

The hardware system uses an **ESP32 microcontroller** with temperature, TDS, and turbidity sensors. Sensor readings are processed by the ESP32 and uploaded to **Firebase Realtime Database** through Wi-Fi for remote monitoring.

## Project Overview

The system monitors three important water parameters:

- **Temperature:** Measures the water temperature.
- **TDS (Total Dissolved Solids):** Estimates the dissolved solids level in water.
- **Turbidity:** Estimates the cloudiness of water.

The collected readings are transmitted to Firebase, where the web dashboard can display the latest sensor values and historical readings.

## Features

- Real-time water parameter monitoring.
- Temperature measurement using DS18B20.
- TDS measurement using an analog TDS sensor.
- Turbidity measurement using an analog turbidity sensor.
- ESP32-based data processing.
- Wireless data transmission through Wi-Fi.
- Firebase Realtime Database integration.
- Web-based monitoring dashboard.
- Historical sensor data storage.

## Hardware Components

| Component | Model / Type | Purpose |
|---|---|---|
| Microcontroller | ESP32 | Main controller and Wi-Fi communication |
| Temperature Sensor | DS18B20 | Measures water temperature |
| TDS Sensor | DFRobot SEN0244 | Measures total dissolved solids |
| Turbidity Sensor | DFRobot SEN0189 | Measures water turbidity |
| Display | 16×2 LCD with I2C | Planned: displays sensor readings |
| Buzzer | Active buzzer | Planned: provides alert indication |
| LEDs | Indicator LEDs | Planned: indicates system status |
| Power Supply | Suitable regulated supply | Powers the circuit |

## Pin Connections

### ESP32 Sensor Connections

| Sensor / Module | ESP32 Pin |
|---|---|
| DS18B20 Data | GPIO 4 |
| TDS Analog Output | GPIO 34 |
| Turbidity Analog Output | GPIO 35 |

### Proposed Additional Connections

| Component | ESP32 Pin |
|---|---|
| LCD SDA | GPIO 21 |
| LCD SCL | GPIO 22 |
| System LED | GPIO 18 |
| Wi-Fi LED | GPIO 19 |
| Alert LED | GPIO 23 |
| Buzzer Control | GPIO 26 |

**Note:** LCD, buzzer, and LED connections are proposed additions and are not yet integrated into the current firmware.

## Working Principle

1. The DS18B20 sensor measures the water temperature.
2. The TDS sensor provides an analog signal corresponding to dissolved solids.
3. The turbidity sensor provides an analog signal corresponding to water cloudiness.
4. The ESP32 reads the sensor values through its digital and analog input pins.
5. The ESP32 processes the readings and applies the programmed calculations.
6. The ESP32 connects to Wi-Fi and uploads the readings to Firebase Realtime Database.
7. The web dashboard retrieves and displays the sensor information.

## Software and Technologies

| Software / Technology | Application |
|---|---|
| Arduino IDE | ESP32 firmware development |
| Embedded C++ | Microcontroller programming |
| Firebase Realtime Database | Cloud data storage |
| HTML | Dashboard structure |
| CSS | Dashboard styling |
| JavaScript | Dashboard functionality |
| Wi-Fi | Wireless communication |
| NTP | Time synchronization |

## Firebase Database Structure

The firmware uses the following Firebase database paths:

```text
SENSOR_DATA
SENSOR_HISTORY
```

- `SENSOR_DATA` stores the latest sensor readings.
- `SENSOR_HISTORY` stores historical sensor records.

The ESP32 sends data to Firebase using HTTP requests over a secure connection.

## Repository Structure

```text
JalSanket/
│
├── README.md
│
├── ESP32_Firmware/
│   └── JalSanket.ino
│
├── Web_Dashboard/
│   └── index.html
│
├── Documentation/
│   └── Project_Report.pdf
│
└── Images/
    └── circuit_diagram.png
```

## Important Technical Notes

- The DS18B20 uses the OneWire communication protocol.
- The current firmware uses ESP32 ADC pins GPIO 34 and GPIO 35 for analog sensor readings.
- The DS18B20 data line requires a suitable pull-up resistor, commonly 4.7 kΩ.
- ESP32 GPIO pins are not 5 V tolerant. Ensure analog sensor outputs do not exceed 3.3 V. Use a suitable voltage divider or level-conditioning circuit where required.
- The turbidity value is an experimental estimate based on the calibration values used in the firmware.
- TDS and turbidity readings require suitable calibration for reliable measurements.
- TDS, turbidity, and temperature readings alone cannot confirm that water is safe to drink.

## Current Implementation Status

| Feature | Status |
|---|---|
| ESP32 sensor interfacing | Implemented |
| DS18B20 temperature monitoring | Implemented |
| TDS monitoring | Implemented |
| Turbidity monitoring | Implemented |
| Wi-Fi connectivity | Implemented |
| Firebase data upload | Implemented |
| Live sensor data | Implemented |
| Historical data storage | Implemented |
| Web dashboard | Developed |
| LCD display | Planned |
| Buzzer alerts | Planned |
| LED indicators | Planned |

## Future Scope

- Integration of LCD for local display.
- Addition of buzzer and LED-based alerts.
- Integration of additional water quality sensors, such as pH.
- Improved sensor calibration for more reliable readings.
- Addition of suitable water filtration and purification methods.
- Mobile application integration.

## Limitations

The prototype monitors selected water parameters. It does not directly detect bacteria, viruses, or all harmful chemical contaminants. Therefore, its readings should not be treated as certification of drinking-water safety.

## Project Objective

The main objective of JalSanket is to develop an affordable IoT-based water monitoring prototype that collects water-quality parameters, sends them to a cloud database, and makes the information accessible through a web dashboard.

## Contributors

**Project:** JalSanket – IoT-Based Water Quality Monitoring System

**Department:** Electronics and Telecommunication Engineering

**Institute:** ICRE Gargoti

---

**Note:** Update the repository structure, contributor names, and project images before publishing.
