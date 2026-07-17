package com.uniseek.service;

import com.uniseek.common.PageResult;
import com.uniseek.dto.EnterpriseRequest;
import com.uniseek.dto.HotEnterpriseVO;
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
     * 分页获取已认证的企业列表（供求职者查看），支持筛选和排序
     *
     * @param page      页码
     * @param pageSize  每页条数
     * @param keyword   搜索关键词（模糊匹配企业名称）
     * @param industry  行业筛选（精确匹配）
     * @param regionId  地区筛选（匹配该地区及其子级）
     * @param sortBy    排序字段：jobCount / avgSalary / null（创建时间倒序）
     * @param sortOrder 排序方向：asc / desc
     * @return 分页企业列表
     */
    PageResult<Enterprise> listPublished(int page, int pageSize, String keyword, String industry, Long regionId,
                                         String sortBy, String sortOrder);

    /**
     * 获取热门企业列表（按投递数、在招岗位数、总名额综合评分排序）
     *
     * @param limit 返回数量
     * @return 热门企业列表
     */
    List<HotEnterpriseVO> getHotEnterprises(int limit);

    /**
     * 根据 ID 获取企业信息
     *
     * @param id 企业 ID
     * @return 企业信息，不存在时返回 null
     */
    Enterprise getById(Long id);
}
