package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 传感器遥测数据上报请求
 *
 * 传感器外设仅上报温度和湿度两个字段
 */
@Data
public class TelemetryRequest {

    /** 温度（摄氏度），保留两位小数 */
    @NotNull(message = "温度不能为空")
    private Double temperature;

    /** 相对湿度（%RH），保留两位小数 */
    @NotNull(message = "湿度不能为空")
    private Double humidity;
}
