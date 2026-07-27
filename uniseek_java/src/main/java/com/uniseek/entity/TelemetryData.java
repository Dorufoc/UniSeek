package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 传感器遥测数据实体
 */
@Data
@TableName("telemetry_data")
public class TelemetryData {

    /** 主键 */
    @TableId
    private Long id;

    /** 温度（摄氏度） */
    private Double temperature;

    /** 湿度（百分比） */
    private Double humidity;

    /** 设备标识 */
    private String deviceId;

    /** 传感器上报时间 */
    private LocalDateTime reportTime;

    /** 记录创建时间 */
    private LocalDateTime createTime;
}
