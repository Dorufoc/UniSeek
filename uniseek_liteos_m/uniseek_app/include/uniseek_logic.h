#ifndef UNISEEK_LOGIC_H
#define UNISEEK_LOGIC_H

typedef enum {
    UNISEEK_HEALTH_RED = 0,
    UNISEEK_HEALTH_YELLOW,
    UNISEEK_HEALTH_GREEN,
} UniseekHealthColor;

int UniseekParseHttpStatus(const char *response);
UniseekHealthColor UniseekSelectHealthColor(int wifiConnected, int sensorValid, int uploadSucceeded);

#endif
