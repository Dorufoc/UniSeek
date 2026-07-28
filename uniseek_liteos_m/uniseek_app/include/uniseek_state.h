#ifndef UNISEEK_STATE_H
#define UNISEEK_STATE_H

#include <stdint.h>

typedef enum {
    UNISEEK_WIFI_DISCONNECTED = 0,
    UNISEEK_WIFI_CONNECTING,
    UNISEEK_WIFI_CONNECTED,
} UniseekWifiStatus;

typedef struct {
    UniseekWifiStatus wifiStatus;
    uint32_t ipAddress;
    double temperature;
    double humidity;
    int sensorValid;
    int uploadSucceeded;
    int httpStatus;
    int lastError;
    unsigned int retryCount;
} UniseekState;

int UniseekStateInit(void);
void UniseekStateGet(UniseekState *state);
void UniseekStateSetWifi(UniseekWifiStatus status, uint32_t ipAddress, int error);
void UniseekStateSetSensor(double temperature, double humidity, int valid, int error);
void UniseekStateSetUpload(int succeeded, int httpStatus, int error, unsigned int retryCount);

#endif
