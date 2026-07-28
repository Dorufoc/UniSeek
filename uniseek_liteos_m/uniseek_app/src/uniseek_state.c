#include <string.h>

#include "los_mux.h"
#include "los_task.h"
#include "uniseek_state.h"

static UniseekState g_state;
static unsigned int g_stateMux;

int UniseekStateInit(void)
{
    if (LOS_MuxCreate(&g_stateMux) != LOS_OK) {
        return -1;
    }
    memset(&g_state, 0, sizeof(g_state));
    return 0;
}

void UniseekStateGet(UniseekState *state)
{
    if (state == NULL) {
        return;
    }
    if (LOS_MuxPend(g_stateMux, LOS_WAIT_FOREVER) == LOS_OK) {
        *state = g_state;
        (void)LOS_MuxPost(g_stateMux);
    }
}

void UniseekStateSetWifi(UniseekWifiStatus status, uint32_t ipAddress, int error)
{
    if (LOS_MuxPend(g_stateMux, LOS_WAIT_FOREVER) == LOS_OK) {
        g_state.wifiStatus = status;
        g_state.ipAddress = ipAddress;
        g_state.lastError = error;
        (void)LOS_MuxPost(g_stateMux);
    }
}

void UniseekStateSetSensor(double temperature, double humidity, int valid, int error)
{
    if (LOS_MuxPend(g_stateMux, LOS_WAIT_FOREVER) == LOS_OK) {
        if (valid) {
            g_state.temperature = temperature;
            g_state.humidity = humidity;
        }
        g_state.sensorValid = valid;
        g_state.lastError = error;
        (void)LOS_MuxPost(g_stateMux);
    }
}

void UniseekStateSetUpload(int succeeded, int httpStatus, int error, unsigned int retryCount)
{
    if (LOS_MuxPend(g_stateMux, LOS_WAIT_FOREVER) == LOS_OK) {
        g_state.uploadSucceeded = succeeded;
        g_state.httpStatus = httpStatus;
        g_state.lastError = error;
        g_state.retryCount = retryCount;
        (void)LOS_MuxPost(g_stateMux);
    }
}
