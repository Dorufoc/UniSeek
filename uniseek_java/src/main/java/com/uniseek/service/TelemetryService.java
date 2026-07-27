package com.uniseek.service;

import com.uniseek.dto.TelemetryRequest;

/**
 * 遥测数据服务接口
 */
public interface TelemetryService {

    /**
     * 接收并保存传感器上报的遥测数据
     *
     * @param request 遥测数据请求
     */
    void report(TelemetryRequest request);
}
