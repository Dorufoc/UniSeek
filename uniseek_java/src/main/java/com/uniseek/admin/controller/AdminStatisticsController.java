package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 管理后台 —— 数据统计控制器
 */
@RestController
@RequestMapping("/api/admin/statistics")
public class AdminStatisticsController {

    @Autowired
    private AdminService adminService;

    /**
     * 数据统计
     * GET /api/admin/statistics
     *
     * @param startDate 开始日期（格式：yyyy-MM-dd HH:mm:ss）
     * @param endDate   结束日期（格式：yyyy-MM-dd HH:mm:ss）
     * @return 统计数据（含 summary 汇总 + dailyList 每日明细）
     */
    @GetMapping
    public ApiResult<Map<String, Object>> getStatistics(
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime endDate) {
        Map<String, Object> statistics = adminService.getStatistics(startDate, endDate);
        return ApiResult.success(statistics);
    }
}
