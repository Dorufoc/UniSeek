#include <stdio.h>

#include "lcd.h"
#include "los_task.h"
#include "lwip/inet.h"
#include "uniseek_config.h"
#include "uniseek_display.h"
#include "uniseek_rgb.h"
#include "uniseek_state.h"

int UniseekDisplayInit(void)
{
    if (lcd_init() != 0) {
        return -1;
    }
    lcd_fill(0, 0, LCD_W, LCD_H, LCD_WHITE);
    return 0;
}

void UniseekDisplayTask(void)
{
    UniseekState state;
    const char *wifiText;
    char line[48];

    while (1) {
        UniseekStateGet(&state);
        wifiText = state.wifiStatus == UNISEEK_WIFI_CONNECTED ? "CONNECTED" :
            state.wifiStatus == UNISEEK_WIFI_CONNECTING ? "CONNECTING" : "DISCONNECTED";
        lcd_fill(0, 0, LCD_W, LCD_H, LCD_WHITE);
        snprintf(line, sizeof(line), "WiFi: %s", wifiText);
        lcd_show_string(0, 16, (const unsigned char *)line, LCD_BLUE, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "IP: %s", state.ipAddress ? inet_ntoa(state.ipAddress) : "0.0.0.0");
        lcd_show_string(0, 44, (const unsigned char *)line, LCD_BLUE, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "Temp: %.2f C", state.temperature);
        lcd_show_string(0, 72, (const unsigned char *)line, LCD_RED, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "Humi: %.2f %%", state.humidity);
        lcd_show_string(0, 100, (const unsigned char *)line, LCD_RED, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "Server: %s", state.uploadSucceeded ? "OK" : "FAIL");
        lcd_show_string(0, 128, (const unsigned char *)line, LCD_GREEN, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "HTTP:%d Retry:%u", state.httpStatus, state.retryCount);
        lcd_show_string(0, 156, (const unsigned char *)line, LCD_BLACK, LCD_WHITE, 16, 0);
        snprintf(line, sizeof(line), "Error:%d Sensor:%s", state.lastError, state.sensorValid ? "OK" : "FAIL");
        lcd_show_string(0, 184, (const unsigned char *)line, LCD_BLACK, LCD_WHITE, 16, 0);
        UniseekRgbUpdate();
        LOS_Msleep(UNISEEK_DISPLAY_INTERVAL_MS);
    }
}
