#include <stdio.h>

#include "iot_pwm.h"
#include "uniseek_logic.h"
#include "uniseek_rgb.h"
#include "uniseek_state.h"

#define UNISEEK_LED_R EPWMDEV_PWM1_M1
#define UNISEEK_LED_G EPWMDEV_PWM7_M1
#define UNISEEK_LED_B EPWMDEV_PWM0_M1
#define UNISEEK_LED_FREQUENCY 1000

static unsigned int UniseekRgbDuty(unsigned char value)
{
    unsigned int duty = ((unsigned int)value * 99U + 127U) / 255U;
    return duty == 0 ? 1 : duty;
}

static void UniseekRgbSet(unsigned char red, unsigned char green, unsigned char blue)
{
    (void)IoTPwmStart(UNISEEK_LED_R, UniseekRgbDuty(red), UNISEEK_LED_FREQUENCY);
    (void)IoTPwmStart(UNISEEK_LED_G, UniseekRgbDuty(green), UNISEEK_LED_FREQUENCY);
    (void)IoTPwmStart(UNISEEK_LED_B, UniseekRgbDuty(blue), UNISEEK_LED_FREQUENCY);
}

int UniseekRgbInit(void)
{
    if (IoTPwmInit(UNISEEK_LED_R) != 0 || IoTPwmInit(UNISEEK_LED_G) != 0 || IoTPwmInit(UNISEEK_LED_B) != 0) {
        printf("uniseek: rgb initialization failed\n");
        return -1;
    }
    UniseekRgbSet(255, 0, 0);
    return 0;
}

void UniseekRgbUpdate(void)
{
    UniseekState state;
    UniseekHealthColor color;

    UniseekStateGet(&state);
    color = UniseekSelectHealthColor(state.wifiStatus == UNISEEK_WIFI_CONNECTED, state.sensorValid, state.uploadSucceeded);
    if (color == UNISEEK_HEALTH_RED) {
        UniseekRgbSet(255, 0, 0);
    } else if (color == UNISEEK_HEALTH_YELLOW) {
        UniseekRgbSet(255, 255, 0);
    } else {
        UniseekRgbSet(0, 255, 0);
    }
}
