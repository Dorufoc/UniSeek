#include <stdint.h>

#include "iot_i2c.h"
#include "iot_errno.h"
#include "uniseek_sensor.h"

#define UNISEEK_SHT30_I2C EI2C0_M2
#define UNISEEK_SHT30_ADDRESS 0x44

static unsigned char UniseekSensorCrc(const unsigned char *data, unsigned char size)
{
    unsigned char crc = 0xff;
    unsigned char i;
    unsigned char bit;

    for (i = 0; i < size; i++) {
        crc ^= data[i];
        for (bit = 0; bit < 8; bit++) {
            crc = (crc & 0x80) ? (unsigned char)((crc << 1) ^ 0x31) : (unsigned char)(crc << 1);
        }
    }
    return crc;
}

int UniseekSensorInit(void)
{
    unsigned char command[2] = {0x22, 0x36};

    if (IoTI2cInit(UNISEEK_SHT30_I2C, EI2C_FRE_400K) != IOT_SUCCESS) {
        return -1;
    }
    return IoTI2cWrite(UNISEEK_SHT30_I2C, UNISEEK_SHT30_ADDRESS, command, sizeof(command)) == IOT_SUCCESS ? 0 : -1;
}

int UniseekSensorRead(double *temperature, double *humidity)
{
    unsigned char command[2] = {0xe0, 0x00};
    unsigned char data[6] = {0};
    uint16_t rawTemperature;
    uint16_t rawHumidity;

    if (temperature == 0 || humidity == 0 || IoTI2cWrite(UNISEEK_SHT30_I2C, UNISEEK_SHT30_ADDRESS, command, sizeof(command)) != IOT_SUCCESS ||
        IoTI2cRead(UNISEEK_SHT30_I2C, UNISEEK_SHT30_ADDRESS, data, sizeof(data)) != IOT_SUCCESS ||
        UniseekSensorCrc(data, 2) != data[2] || UniseekSensorCrc(&data[3], 2) != data[5]) {
        return -1;
    }
    rawTemperature = ((uint16_t)data[0] << 8) | data[1];
    rawHumidity = ((uint16_t)data[3] << 8) | data[4];
    *temperature = -45.0 + 175.0 * rawTemperature / 65535.0;
    *humidity = 100.0 * rawHumidity / 65535.0;
    return 0;
}
