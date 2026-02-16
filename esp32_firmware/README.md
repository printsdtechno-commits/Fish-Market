# ESP32 Fish Market Weighing Scale Firmware

## Hardware Requirements

- **ESP32 Development Board**
- **HX711 Load Cell Amplifier**
- **Load Cell** (appropriate capacity for fish weighing, e.g., 50kg)
- **SIM800L or SIM7600** GSM/LTE Module
- **SIM Card** with data plan
- **Power Supply** (5V for ESP32, may need separate supply for GSM module)

## Wiring Connections

### HX711 to ESP32
- VCC → 3.3V
- GND → GND
- DT (DOUT) → GPIO 4
- SCK → GPIO 5

### Load Cell to HX711
- Red → E+
- Black → E-
- White → A-
- Green → A+

### SIM800L/SIM7600 to ESP32
- VCC → 5V (use external power if needed)
- GND → GND
- TXD → RX2 (GPIO 16)
- RXD → TX2 (GPIO 17)

## Required Libraries

Install these libraries in Arduino IDE:

1. **HX711** by Bodge
   - Sketch → Include Library → Manage Libraries → Search "HX711"

2. **ArduinoJson** by Benoit Blanchon
   - Sketch → Include Library → Manage Libraries → Search "ArduinoJson"

3. **HTTPClient** (Built-in with ESP32 board support)

## Configuration

Before uploading, configure these parameters in the code:

```cpp
const char* apn = "your_apn";  // Your SIM card APN
const char* firebaseHost = "YOUR_FIREBASE_PROJECT.firebaseio.com";
const char* firebaseAuth = "YOUR_FIREBASE_AUTH_TOKEN";
const char* machineId = "MACHINE_001";  // Unique machine ID
float calibration_factor = 2280.0;  // Adjust after calibration
```

### Firebase Setup

1. Create a Firebase Realtime Database
2. Generate a database secret from Firebase Console
3. Set up database rules:

```json
{
  "rules": {
    "weighing_machines": {
      "$machineId": {
        ".write": "auth != null",
        ".read": "auth != null"
      }
    }
  }
}
```

## Calibration Process

1. Upload the firmware to ESP32
2. Open Serial Monitor (115200 baud)
3. Remove all weight from scale
4. Press 't' to tare the scale
5. Press 'c' to start calibration
6. Remove all weight when prompted
7. Place a known weight (e.g., 5 kg) when prompted
8. Enter the exact weight in kg
9. Wait for calibration to complete
10. Note the calibration factor displayed

## Features

- **Auto-tare on startup** - Automatically zeros the scale
- **Live weight transmission** - Sends weight to Firebase every 2 seconds
- **Tamper-proof** - Calibration lock prevents unauthorized changes
- **Serial commands**:
  - `t` - Tare (zero) the scale
  - `c` - Calibrate the scale
- **GSM/LTE connectivity** - Works without WiFi using SIM card
- **Error handling** - Negative weights are treated as zero

## Troubleshooting

### Scale not reading correctly
- Check load cell wiring
- Verify HX711 connections
- Run calibration process
- Ensure load cell is not damaged

### No GSM connection
- Check SIM card is inserted
- Verify SIM card has data plan active
- Check APN settings
- Ensure antenna is connected (if required)

### Firebase not updating
- Verify Firebase credentials
- Check internet connectivity
- Review Firebase database rules
- Check serial monitor for error messages

## Power Considerations

- ESP32: ~500mA peak
- HX711: ~10mA
- SIM800L: ~2A peak during transmission
- SIM7600: ~2A peak during transmission

**Recommendation**: Use 5V 3A power supply with proper voltage regulation.

## Security Notes

- Keep Firebase auth token secure
- Change default machine ID
- Enable calibration lock in production
- Use HTTPS for all communications
- Store sensitive data in environment variables or secure storage

## Maintenance

- Regularly check load cell mounting
- Clean load cell surface
- Verify calibration monthly
- Monitor SIM card data usage
- Check battery/power supply voltage

## Support

For issues or questions:
1. Check serial monitor output
2. Verify all connections
3. Test with known weights
4. Review Firebase logs
