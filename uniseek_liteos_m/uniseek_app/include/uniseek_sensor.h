#ifndef UNISEEK_SENSOR_H
#define UNISEEK_SENSOR_H

int UniseekSensorInit(void);
int UniseekSensorRead(double *temperature, double *humidity);

#endif
