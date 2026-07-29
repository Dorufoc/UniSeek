package com.uniseek.service;

import com.uniseek.dto.LatestTelemetryResponse;
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

    /**
     * 查询最新一条已入库遥测数据
     *
     * @return 最新温湿度数据，无数据时返回 null
     */
    LatestTelemetryResponse getLatest();
}
