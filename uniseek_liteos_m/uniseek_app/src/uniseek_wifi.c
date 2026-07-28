#include <stdio.h>

#include "config_network.h"
#include "los_task.h"
#include "uniseek_config.h"
#include "uniseek_state.h"
#include "uniseek_wifi.h"

static void UniseekWifiConnect(void)
{
    FlashInit();
    (void)VendorSet(VENDOR_ID_WIFI_MODE, "STA", 3);
    (void)VendorSet(VENDOR_ID_WIFI_ROUTE_SSID, UNISEEK_WIFI_SSID, sizeof(UNISEEK_WIFI_SSID));
    (void)VendorSet(VENDOR_ID_WIFI_ROUTE_PASSWD, UNISEEK_WIFI_PASSWORD, sizeof(UNISEEK_WIFI_PASSWORD));
    SetWifiModeOff();
    SetWifiModeOn();
}

void UniseekWifiTask(void)
{
    WifiLinkedInfo info;

    UniseekWifiConnect();
    while (1) {
        if (GetLinkedInfo(&info) == WIFI_SUCCESS && info.connState == WIFI_CONNECTED && info.ipAddress != 0) {
            UniseekStateSetWifi(UNISEEK_WIFI_CONNECTED, info.ipAddress, 0);
        } else {
            UniseekStateSetWifi(UNISEEK_WIFI_CONNECTING, 0, -1);
            UniseekWifiConnect();
            printf("uniseek: wifi reconnecting\n");
        }
        LOS_Msleep(UNISEEK_WIFI_RECONNECT_INTERVAL_MS);
    }
}
