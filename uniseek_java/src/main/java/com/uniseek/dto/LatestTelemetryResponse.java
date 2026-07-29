package com.uniseek.dto;

import java.time.LocalDateTime;

/**
 * 最新温湿度遥测数据响应
 */
public class LatestTelemetryResponse {

    /** 温度（摄氏度） */
    private Double temperature;

    /** 湿度（百分比） */
    private Double humidity;

    /** 传感器上报时间 */
    private LocalDateTime reportTime;

    public LatestTelemetryResponse() {
    }

    public LatestTelemetryResponse(Double temperature, Double humidity, LocalDateTime reportTime) {
        this.temperature = temperature;
        this.humidity = humidity;
        this.reportTime = reportTime;
    }

    public Double getTemperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature;
    }

    public Double getHumidity() {
        return humidity;
    }

    public void setHumidity(Double humidity) {
        this.humidity = humidity;
    }

    public LocalDateTime getReportTime() {
        return reportTime;
    }

    public void setReportTime(LocalDateTime reportTime) {
        this.reportTime = reportTime;
    }
}
