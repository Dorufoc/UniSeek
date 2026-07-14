package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.entity.Task;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 管理后台 —— 职位审核控制器
 */
@RestController
@RequestMapping("/api/admin/tasks")
public class AdminTaskController {

    @Autowired
    private AdminService adminService;

    /**
     * 待审核职位列表
     * GET /api/admin/tasks/pending
     *
     * @param page     页码（默认 1）
     * @param pageSize 每页条数（默认 10）
     * @return 待审核职位分页结果
     */
    @GetMapping("/pending")
    public ApiResult<PageResult<Task>> listPendingTasks(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        PageResult<Task> result = adminService.listPendingTasks(page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * 职位审核
     * PUT /api/admin/tasks/{id}/audit
     *
     * @param id           职位 ID
     * @param approved     是否通过（true=通过，false=驳回）
     * @param rejectReason 驳回原因（驳回时必填）
     * @return 操作结果
     */
    @PutMapping("/{id}/audit")
    public ApiResult<Map<String, Object>> auditTask(
            @PathVariable Long id,
            @RequestParam boolean approved,
            @RequestParam(required = false) String rejectReason) {
        adminService.auditTask(id, approved, rejectReason);
        String message = approved ? "职位审核已通过并发布" : "职位审核已驳回";
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("approved", approved);
        return ApiResult.success(message, data);
    }
}
