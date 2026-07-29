package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.dto.LatestTelemetryResponse;
import com.uniseek.dto.TelemetryRequest;
import com.uniseek.service.TelemetryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.HashMap;
import java.util.Map;

/**
 * 传感器遥测数据控制器
 *
 * 传感器外设通过 POST 请求定期上报温度和湿度数据；大屏通过 GET 请求读取最新数据
 */
@RestController
@RequestMapping("/api/v1")
public class TelemetryController {

    @Autowired
    private TelemetryService telemetryService;

    /**
     * 接收传感器遥测数据上报
     * POST /api/v1/telemetry
     * <p>
     * 传感器组件仅检查 HTTP 状态码（200-299 视为成功），响应体不解析。
     * 此处统一返回 JSON 格式以便后续扩展。
     *
     * @param request 遥测数据（temperature + humidity）
     * @return HTTP 200 + JSON 响应
     */
    @PostMapping("/telemetry")
    public ResponseEntity<Map<String, Object>> report(@Valid @RequestBody TelemetryRequest request) {
        telemetryService.report(request);

        Map<String, Object> body = new HashMap<>(2);
        body.put("code", 0);
        body.put("message", "sensor data accepted");
        return ResponseEntity.ok(body);
    }

    /**
     * 查询最新一条温湿度遥测数据
     * GET /api/v1/telemetry/latest
     *
     * @return 项目标准 ApiResult 包装，无数据时 data 为 null
     */
    @GetMapping("/telemetry/latest")
    public ApiResult<LatestTelemetryResponse> latest() {
        LatestTelemetryResponse data = telemetryService.getLatest();
        return ApiResult.success(data);
    }
}
