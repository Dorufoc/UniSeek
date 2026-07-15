package com.uniseek.service;

import com.uniseek.dto.EnterpriseRequest;
import com.uniseek.entity.Enterprise;
import java.util.List;

/**
 * 企业资质认证服务接口
 */
public interface EnterpriseService {

    /**
     * 提交企业资质认证
     * <p>
     * 前置条件：
     * <ul>
     *   <li>用户已完成实名认证（real_name_auth.status = 1）</li>
     *   <li>用户未提交过企业资质</li>
     *   <li>统一社会信用代码唯一</li>
     *   <li>企业名称唯一</li>
     * </ul>
     *
     * @param userId  当前用户 ID
     * @param request 企业资质请求
     * @return 创建的企业资质记录
     */
    Enterprise submit(Long userId, EnterpriseRequest request);

    /**
     * 获取当前用户的企业资质信息
     *
     * @param userId 当前用户 ID
     * @return 企业资质记录，不存在时返回 null
     */
    Enterprise getMyEnterprise(Long userId);

    /**
     * 更新企业资质信息（重新提交审核，auditStatus 回 0）
     *
     * @param userId  当前用户 ID
     * @param request 企业资质请求
     * @return 更新后的企业资质记录
     */
    Enterprise update(Long userId, EnterpriseRequest request);

    /**
     * 获取所有已认证的企业列表（供求职者查看）
     *
     * @return 已认证的企业列表
     */
    List<Enterprise> listPublished();
}
