package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.entity.Enterprise;
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
 * 管理后台 —— 企业审核控制器
 */
@RestController
@RequestMapping("/api/admin/enterprises")
public class AdminEnterpriseController {

    @Autowired
    private AdminService adminService;

    /**
     * 企业审核列表（分页）
     * GET /api/admin/enterprises
     *
     * @param page       页码（默认 1）
     * @param pageSize   每页条数（默认 10）
     * @param auditStatus 审核状态筛选（0 待审核 / 1 审核通过 / 2 审核不通过）
     * @return 企业分页结果
     */
    @GetMapping
    public ApiResult<PageResult<Enterprise>> listEnterprises(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) Integer auditStatus) {
        PageResult<Enterprise> result = adminService.listEnterprises(page, pageSize, auditStatus);
        return ApiResult.success(result);
    }

    /**
     * 企业资质审核
     * PUT /api/admin/enterprises/{id}/audit
     *
     * @param id           企业记录 ID
     * @param approved     是否通过（true=通过，false=驳回）
     * @param rejectReason 驳回原因（驳回时必填）
     * @return 操作结果
     */
    @PutMapping("/{id}/audit")
    public ApiResult<Map<String, Object>> auditEnterprise(
            @PathVariable Long id,
            @RequestParam boolean approved,
            @RequestParam(required = false) String rejectReason) {
        adminService.auditEnterprise(id, approved, rejectReason);
        String message = approved ? "企业资质审核已通过" : "企业资质已驳回";
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("approved", approved);
        return ApiResult.success(message, data);
    }
}
