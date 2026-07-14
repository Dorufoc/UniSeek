package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.entity.Complaint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 管理后台 —— 投诉处理控制器
 */
@RestController
@RequestMapping("/api/admin/complaints")
public class AdminComplaintController {

    @Autowired
    private AdminService adminService;

    /**
     * 投诉列表（分页）
     * GET /api/admin/complaints
     *
     * @param page       页码（默认 1）
     * @param pageSize   每页条数（默认 10）
     * @param status     处理状态筛选（0 待处理 / 1 处理中 / 2 已结案）
     * @param targetType 被投诉对象类型筛选（0 职位 / 1 企业 / 2 用户）
     * @return 投诉分页结果
     */
    @GetMapping
    public ApiResult<PageResult<Complaint>> listComplaints(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer targetType) {
        PageResult<Complaint> result = adminService.listComplaints(page, pageSize, status, targetType);
        return ApiResult.success(result);
    }

    /**
     * 投诉详情（含投诉人信息 + 被投诉对象标题）
     * GET /api/admin/complaints/{id}
     *
     * @param id 投诉 ID
     * @return 投诉详情
     */
    @GetMapping("/{id}")
    public ApiResult<Map<String, Object>> getComplaintDetail(@PathVariable Long id) {
        Map<String, Object> detail = adminService.getComplaintDetail(id);
        return ApiResult.success(detail);
    }

    /**
     * 处理投诉
     * PUT /api/admin/complaints/{id}/handle
     *
     * @param id           投诉 ID
     * @param status       目标状态（1 处理中 / 2 已结案）
     * @param handleResult 处理结果
     * @return 操作结果
     */
    @PutMapping("/{id}/handle")
    public ApiResult<Map<String, Object>> handleComplaint(
            @PathVariable Long id,
            @RequestParam Integer status,
            @RequestParam String handleResult) {
        adminService.handleComplaint(id, status, handleResult);
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("status", status);
        data.put("handleResult", handleResult);
        String statusText = status == 1 ? "处理中" : "已结案";
        return ApiResult.success("投诉已" + statusText, data);
    }
}
