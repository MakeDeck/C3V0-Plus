// Copyright (c) 2014 MakeDeck LLC
// Copyright (c) 2013 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

vbat_sns        <- hardware.pinA;   // Battery Voltage Sense (ADC)
vbat_sns.configure(ANALOG_IN);
vbat_sns_en     <- hardware.pinD;
vbat_sns_en.configure(DIGITAL_OUT);
vbat <- 0;
function chkBat() {
    //imp.wakeup(10,chkBat);
    vbat_sns_en.write(1);
    vbat = (vbat_sns.read()/65535.0) * hardware.voltage() * (6.9/4.7);
    vbat_sns_en.write(0);
    server.log(vbat);
    return vbat;
}

class Si7021 {
    static I2CADDR = "\x80";
    static READ_RH = "\xE5";
    static READ_TEMP = "\xE3";
    static WRITEREG = "\xE6";
    static READREG = "\xE7";
    static RESET = "\xFE";
    static RH_MULT      = 125.0/65536.0;
    static RH_ADD       = -6;
    static TEMP_MULT    = 175.72/65536.0;
    static TEMP_ADD     = -46.85;
    
    _i2c = null;
    _addr = null;
    // class constructor
    // Input:
    // _i2c: hardware i2c bus, must pre-configured
    // _addr: slave address (optional)
    // Return: (None)
    constructor(i2c, addr = 0x80)
    {
        _i2c = i2c;
        _addr = addr;
    }
    // read the humidity
    // Input: (none)
    // Return: relative humidity (float)
    function readRH() {
        _i2c.write(_addr, READ_RH);
        imp.sleep(0.1);
        local reading = _i2c.read(_addr, "", 2);
        while (reading == null) {
        reading = _i2c.read(_addr, "", 2);
    }
    local humidity = RH_MULT*((reading[0] << 8) + reading[1]) + RH_ADD;
    return humidity;
    }
    // read the temperature
    // Input: (none)
    // Return: temperature in celsius (float)
    function readTemp() {
        _i2c.write(_addr, READ_TEMP);
        imp.sleep(0.1);
        local reading = _i2c.read(_addr, "", 2);
        while (reading == null) {
        reading = _i2c.read(_addr, "", 2);
        }
        //local temperature = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        local temp_cel = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        local temp_far = (temp_cel*1.8 + 32);
        return temp_far;
    }
    // read the temperature from previous rh measurement
    // this method does not have to recalculate temperature so it is faster
    // Input: (none)
    // Return: temperature in celsius (float)
    function reset() {
        server.log(_i2c.write(_addr, RESET));
        imp.sleep(0.2);
    }
}
    // Configure i2c bus
hardware.i2c89.configure(CLOCK_SPEED_100_KHZ);
    // Create SI7021 object
sensor <- Si7021(hardware.i2c89)
sensor.reset();

function chkSensor() {
    //imp.wakeup(10, chkSensor);
    humidity <- sensor.readRH();
    temperature <- sensor.readTemp();
    server.log(format("Temperature: %0.1fF & Humidity: %0.1f", temperature, humidity) + "%");
    
}
    
chkBat();
chkSensor();
data <- {"temperature" : format("%0.1f", temperature), "humidity" : format("%0.1f", humidity), "batt" : format("%0.1f", vbat)};
agent.send("data", data);

imp.setpowersave(true);

imp.onidle(function() {
    server.expectonlinein(32);
    imp.deepsleepfor(30);
});
