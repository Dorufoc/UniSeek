#include <stdio.h>

#include "los_task.h"
#include "ohos_init.h"
#include "uniseek_config.h"
#include "uniseek_display.h"
#include "uniseek_http.h"
#include "uniseek_rgb.h"
#include "uniseek_sensor.h"
#include "uniseek_state.h"
#include "uniseek_wifi.h"

static int UniseekCreateTask(TSK_ENTRY_FUNC entry, const char *name, unsigned short priority, unsigned int stackSize)
{
    unsigned int taskId;
    TSK_INIT_PARAM_S task = {0};

    task.pfnTaskEntry = entry;
    task.uwStackSize = stackSize;
    task.pcName = (char *)name;
    task.usTaskPrio = priority;
    if (LOS_TaskCreate(&taskId, &task) != LOS_OK) {
        printf("uniseek: task creation failed: %s\n", name);
        return -1;
    }
    return 0;
}

static void UniseekSensorTask(void)
{
    double temperature;
    double humidity;

    while (1) {
        if (UniseekSensorRead(&temperature, &humidity) == 0) {
            UniseekStateSetSensor(temperature, humidity, 1, 0);
        } else {
            UniseekStateSetSensor(0, 0, 0, -2);
            printf("uniseek: sensor read failed\n");
        }
        LOS_Msleep(UNISEEK_SAMPLE_INTERVAL_MS);
    }
}

static void UniseekUploadTask(void)
{
    UniseekState state;
    int httpStatus;
    unsigned int attempt;

    while (1) {
        UniseekStateGet(&state);
        if (state.wifiStatus != UNISEEK_WIFI_CONNECTED || !state.sensorValid) {
            UniseekStateSetUpload(0, 0, -3, 0);
        } else {
            for (attempt = 1; attempt <= UNISEEK_HTTP_RETRY_COUNT; attempt++) {
                if (UniseekHttpPost(state.temperature, state.humidity, &httpStatus) == 0) {
                    UniseekStateSetUpload(1, httpStatus, 0, attempt - 1);
                    break;
                }
                UniseekStateSetUpload(0, 0, -4, attempt);
                if (attempt < UNISEEK_HTTP_RETRY_COUNT) {
                    LOS_Msleep(UNISEEK_HTTP_RETRY_INTERVAL_MS);
                }
            }
        }
        LOS_Msleep(UNISEEK_SAMPLE_INTERVAL_MS);
    }
}

void uniseek_app(void)
{
    if (UniseekStateInit() != 0 || UniseekSensorInit() != 0 || UniseekDisplayInit() != 0 || UniseekRgbInit() != 0) {
        printf("uniseek: initialization failed\n");
        return;
    }
    (void)UniseekCreateTask((TSK_ENTRY_FUNC)UniseekWifiTask, "uniseek_wifi", 23, 4096);
    (void)UniseekCreateTask((TSK_ENTRY_FUNC)UniseekSensorTask, "uniseek_sensor", 24, 4096);
    (void)UniseekCreateTask((TSK_ENTRY_FUNC)UniseekUploadTask, "uniseek_upload", 25, 6144);
    (void)UniseekCreateTask((TSK_ENTRY_FUNC)UniseekDisplayTask, "uniseek_display", 26, 4096);
}

APP_FEATURE_INIT(uniseek_app);
