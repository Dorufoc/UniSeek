package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.common.util.UserContext;
import com.uniseek.dto.EnterpriseRequest;
import com.uniseek.dto.HotEnterpriseVO;
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
    @OperationLog(operationType = "ENTERPRISE_SUBMIT", targetType = "ENTERPRISE")
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
    public ApiResult<Enterprise> getMyEnterprise() {
        Long userId = UserContext.getUserId();
        Enterprise enterprise = enterpriseService.getMyEnterprise(userId);
        return ApiResult.success(enterprise);
    }

    /**
     * 分页获取已认证的企业列表（供求职者浏览），支持关键词/行业/地区筛选和排序
     * GET /api/enterprise/list?page=1&pageSize=12&keyword=&industry=&regionId=&sortBy=jobCount&sortOrder=desc
     */
    @GetMapping("/list")
    public ApiResult<PageResult<Enterprise>> listEnterprises(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "12") int pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String industry,
            @RequestParam(required = false) Long regionId,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortOrder) {
        PageResult<Enterprise> result = enterpriseService.listPublished(page, pageSize, keyword, industry, regionId, sortBy, sortOrder);
        return ApiResult.success(result);
    }

    /**
     * 获取热门企业列表（按综合热度评分排序）
     * GET /api/enterprise/hot?limit=12
     */
    @GetMapping("/hot")
    public ApiResult<List<HotEnterpriseVO>> getHotEnterprises(@RequestParam(defaultValue = "12") int limit) {
        List<HotEnterpriseVO> list = enterpriseService.getHotEnterprises(limit);
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
    @OperationLog(operationType = "ENTERPRISE_SUBMIT", targetType = "ENTERPRISE")
    public ApiResult<Enterprise> update(@Valid @RequestBody EnterpriseRequest request) {
        Long userId = UserContext.getUserId();
        Enterprise enterprise = enterpriseService.update(userId, request);
        return ApiResult.success("更新成功，等待重新审核", enterprise);
    }
}
