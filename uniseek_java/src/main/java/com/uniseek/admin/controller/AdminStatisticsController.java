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
import java.util.List;
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

    /**
     * 职位大类需求占比
     * GET /api/admin/statistics/categories（大屏公开，无需鉴权）
     *
     * @param range 时间范围：24h / 7d / 30d / 12m / 10y，默认 7d
     */
    @GetMapping("/categories")
    public ApiResult<List<Map<String, Object>>> getCategoryDistribution(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getCategoryDistribution(range));
    }

    /**
     * 实时动态
     * GET /api/admin/statistics/latest-activity（大屏公开，无需鉴权）
     */
    @GetMapping("/latest-activity")
    public ApiResult<List<Map<String, Object>>> getLatestActivity() {
        return ApiResult.success(adminService.getLatestActivity());
    }

    /**
     * 热门岗位 TOP10
     * GET /api/admin/statistics/hot-tasks（大屏公开，无需鉴权）
     *
     * @param range 时间范围：24h / 7d / 30d / 12m / 10y，默认 7d
     */
    @GetMapping("/hot-tasks")
    public ApiResult<List<Map<String, Object>>> getHotTasks(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getHotTasks(range));
    }

    /**
     * 人才流向数据
     * GET /api/admin/statistics/talent-flow
     *
     * @param range 时间范围：24h / 7d / 30d / 12m / 10y，默认 7d
     */
    @GetMapping("/talent-flow")
    public ApiResult<List<Map<String, Object>>> getTalentFlow(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getTalentFlow(range));
    }

    /**
     * 大屏 KPI 汇总（公开接口，无需鉴权）
     * GET /api/admin/statistics/summary
     */
    @GetMapping("/summary")
    public ApiResult<Map<String, Object>> getScreenSummary(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getScreenSummary(range));
    }

    /**
     * 投递转化漏斗
     * GET /api/admin/statistics/application-funnel
     *
     * @param range 时间范围：24h / 7d / 30d / 12m / 10y，默认 7d
     */
    @GetMapping("/application-funnel")
    public ApiResult<Map<String, Object>> getApplicationFunnel(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getApplicationFunnel(range));
    }

    /**
     * 企业审核 + 实名认证统计
     * GET /api/admin/statistics/enterprise-summary
     *
     * @param range 时间范围：24h / 7d / 30d / 12m / 10y，默认 7d
     */
    @GetMapping("/enterprise-summary")
    public ApiResult<Map<String, Object>> getEnterpriseSummary(
            @RequestParam(required = false, defaultValue = "7d") String range) {
        return ApiResult.success(adminService.getEnterpriseSummary(range));
    }
}
