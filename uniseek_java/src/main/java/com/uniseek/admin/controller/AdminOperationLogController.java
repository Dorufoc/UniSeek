package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.entity.OperationLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

/**
 * 管理后台 —— 操作日志查询控制器
 */
@RestController
@RequestMapping("/api/admin/operation-logs")
public class AdminOperationLogController {

    @Autowired
    private AdminService adminService;

    /**
     * 操作日志查询（分页）
     * GET /api/admin/operation-logs
     *
     * @param page          页码（默认 1）
     * @param pageSize      每页条数（默认 10）
     * @param operatorId    操作人 ID
     * @param operationType 操作类型
     * @param targetType    目标类型
     * @param targetId      目标 ID
     * @param startTime     开始时间（格式：yyyy-MM-dd HH:mm:ss）
     * @param endTime       结束时间（格式：yyyy-MM-dd HH:mm:ss）
     * @return 操作日志分页结果
     */
    @GetMapping
    public ApiResult<PageResult<OperationLog>> listOperationLogs(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) Long operatorId,
            @RequestParam(required = false) String operationType,
            @RequestParam(required = false) String targetType,
            @RequestParam(required = false) String targetId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startTime,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime endTime) {
        PageResult<OperationLog> result = adminService.listOperationLogs(
                page, pageSize, operatorId, operationType, targetType, targetId, startTime, endTime);
        return ApiResult.success(result);
    }
}
