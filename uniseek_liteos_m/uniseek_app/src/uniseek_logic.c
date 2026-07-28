#include <stddef.h>

#include "uniseek_logic.h"

int UniseekParseHttpStatus(const char *response)
{
    int status;

    if (response == NULL || response[0] != 'H' || response[1] != 'T' || response[2] != 'T' ||
        response[3] != 'P' || response[4] != '/' || response[5] != '1' || response[6] != '.') {
        return -1;
    }
    if (response[7] != '0' && response[7] != '1') {
        return -1;
    }
    if (response[8] != ' ' || response[9] < '0' || response[9] > '9' || response[10] < '0' ||
        response[10] > '9' || response[11] < '0' || response[11] > '9') {
        return -1;
    }
    status = (response[9] - '0') * 100 + (response[10] - '0') * 10 + response[11] - '0';
    return status >= 200 && status <= 299 ? status : -1;
}

UniseekHealthColor UniseekSelectHealthColor(int wifiConnected, int sensorValid, int uploadSucceeded)
{
    if (!wifiConnected) {
        return UNISEEK_HEALTH_RED;
    }
    if (!sensorValid || !uploadSucceeded) {
        return UNISEEK_HEALTH_YELLOW;
    }
    return UNISEEK_HEALTH_GREEN;
}
