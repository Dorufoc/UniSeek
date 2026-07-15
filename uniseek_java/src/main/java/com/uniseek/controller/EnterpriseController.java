package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.annotation.OperationLog;
import com.uniseek.common.util.UserContext;
import com.uniseek.dto.EnterpriseRequest;
import com.uniseek.entity.Enterprise;
import com.uniseek.service.EnterpriseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 企业资质认证控制器
 */
@RestController
@RequestMapping("/api/enterprise")
public class EnterpriseController {

    @Autowired
    private EnterpriseService enterpriseService;

    /**
     * 提交企业资质认证
     * POST /api/enterprise（需要鉴权）
     *
     * @param request 企业资质请求
     * @return 企业资质记录
     */
    @PostMapping
    @OperationLog(module = "企业资质", action = "提交", description = "提交企业资质认证")
    public ApiResult<Enterprise> submit(@Valid @RequestBody EnterpriseRequest request) {
        Long userId = UserContext.getUserId();
        Enterprise enterprise = enterpriseService.submit(userId, request);
        return ApiResult.success("提交成功，等待审核", enterprise);
    }

    /**
     * 获取我的企业资质信息
     * GET /api/enterprise/my（需要鉴权）
     *
     * @return 企业资质记录
     */
    @GetMapping("/my")
    @OperationLog(module = "企业资质", action = "查询", description = "查询我的企业资质信息")
    public ApiResult<Enterprise> getMyEnterprise() {
        Long userId = UserContext.getUserId();
        Enterprise enterprise = enterpriseService.getMyEnterprise(userId);
        return ApiResult.success(enterprise);
    }

    /**
     * 获取已认证的企业列表（供求职者浏览）
     * GET /api/enterprise/list
     */
    @GetMapping("/list")
    public ApiResult<List<Enterprise>> listEnterprises() {
        List<Enterprise> list = enterpriseService.listPublished();
        return ApiResult.success(list);
    }

    /**
     * 更新企业资质信息（重新提交审核）
     * PUT /api/enterprise（需要鉴权）
     *
     * @param request 企业资质请求
     * @return 更新后的企业资质记录
     */
    @PutMapping
    @OperationLog(module = "企业资质", action = "更新", description = "更新企业资质信息并重新提交审核")
    public ApiResult<Enterprise> update(@Valid @RequestBody EnterpriseRequest request) {
        Long userId = UserContext.getUserId();
        Enterprise enterprise = enterpriseService.update(userId, request);
        return ApiResult.success("更新成功，等待重新审核", enterprise);
    }
}
