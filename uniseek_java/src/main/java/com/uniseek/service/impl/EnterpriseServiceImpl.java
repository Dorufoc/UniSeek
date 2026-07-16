package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.RealNameAuthMapper;
import com.uniseek.dao.RegionMapper;
import com.uniseek.dto.EnterpriseRequest;
import com.uniseek.dto.HotEnterpriseVO;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.RealNameAuth;
import com.uniseek.entity.Region;
import com.uniseek.service.EnterpriseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 企业资质认证服务实现
 */
@Service
public class EnterpriseServiceImpl implements EnterpriseService {

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private RealNameAuthMapper realNameAuthMapper;

    @Autowired
    private RegionMapper regionMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @OperationLog(operationType = "ENTERPRISE_SUBMIT", targetType = "ENTERPRISE")
    public Enterprise submit(Long userId, EnterpriseRequest request) {
        // 1. 检查用户是否已完成实名认证
        RealNameAuth auth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getUserId, userId)
                        .eq(RealNameAuth::getStatus, 1));

        if (auth == null) {
            throw new BusinessException("请先完成实名认证后再提交企业资质");
        }

        // 2. 检查用户是否已提交过企业资质
        Integer existingCount = enterpriseMapper.selectCount(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getUserId, userId));

        if (existingCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "您已提交过企业资质，请勿重复提交");
        }

        // 3. 检查统一社会信用代码唯一性
        Integer creditCodeCount = enterpriseMapper.selectCount(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getCreditCode, request.getCreditCode().trim()));

        if (creditCodeCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该统一社会信用代码已被注册");
        }

        // 4. 检查企业名称唯一性
        Integer companyNameCount = enterpriseMapper.selectCount(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getCompanyName, request.getCompanyName().trim()));

        if (companyNameCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该企业名称已被注册");
        }

        // 5. 构建企业资质实体
        Enterprise enterprise = new Enterprise();
        enterprise.setUserId(userId);
        enterprise.setCompanyName(request.getCompanyName().trim());
        enterprise.setCreditCode(request.getCreditCode().trim());
        enterprise.setLicenseImgUrl(request.getLicenseImgUrl());
        enterprise.setIndustry(request.getIndustry().trim());
        enterprise.setRegionId(request.getRegionId());
        enterprise.setDescription(request.getDescription());
        enterprise.setAuditStatus(0); // 待审核
        enterprise.setCreateTime(LocalDateTime.now());
        enterprise.setUpdateTime(LocalDateTime.now());

        // 6. 插入企业资质记录
        enterpriseMapper.insert(enterprise);

        return enterprise;
    }

    @Override
    public Enterprise getMyEnterprise(Long userId) {
        return enterpriseMapper.selectOne(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getUserId, userId));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @OperationLog(operationType = "ENTERPRISE_SUBMIT", targetType = "ENTERPRISE")
    public Enterprise update(Long userId, EnterpriseRequest request) {
        // 1. 查询现有企业资质
        Enterprise existing = enterpriseMapper.selectOne(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getUserId, userId));

        if (existing == null) {
            throw new BusinessException("未找到企业资质信息，请先提交");
        }

        // 2. 检查统一社会信用代码唯一性（排除自身）
        Integer creditCodeCount = enterpriseMapper.selectCount(
                new LambdaQueryWrapper<Enterprise>()
                        .ne(Enterprise::getId, existing.getId())
                        .eq(Enterprise::getCreditCode, request.getCreditCode().trim()));

        if (creditCodeCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该统一社会信用代码已被其他企业使用");
        }

        // 3. 检查企业名称唯一性（排除自身）
        Integer companyNameCount = enterpriseMapper.selectCount(
                new LambdaQueryWrapper<Enterprise>()
                        .ne(Enterprise::getId, existing.getId())
                        .eq(Enterprise::getCompanyName, request.getCompanyName().trim()));

        if (companyNameCount > 0) {
            throw new BusinessException(ApiResult.CONFLICT, "该企业名称已被其他企业使用");
        }

        // 4. 更新字段
        existing.setCompanyName(request.getCompanyName().trim());
        existing.setCreditCode(request.getCreditCode().trim());
        existing.setLicenseImgUrl(request.getLicenseImgUrl());
        existing.setIndustry(request.getIndustry().trim());
        existing.setRegionId(request.getRegionId());
        existing.setDescription(request.getDescription());
        existing.setAuditStatus(0); // 重新提交审核
        existing.setUpdateTime(LocalDateTime.now());

        // 5. 更新企业资质
        enterpriseMapper.updateById(existing);

        return existing;
    }

    @Override
    public PageResult<Enterprise> listPublished(int page, int pageSize, String keyword, String industry, Long regionId,
                                                String sortBy, String sortOrder) {
        // 收集子级地区ID
        List<Long> regionIds = null;
        if (regionId != null) {
            regionIds = collectRegionIds(regionId);
        }

        // 执行自定义分页查询（含排序逻辑）
        IPage<Enterprise> pageResult = enterpriseMapper.selectEnterprisePage(
                new Page<>(page, pageSize),
                keyword,
                industry,
                regionIds,
                sortBy,
                sortOrder
        );
        return PageResult.of(pageResult);
    }

    /**
     * 递归收集指定地区及其所有子级地区ID
     */
    private List<Long> collectRegionIds(Long parentId) {
        List<Long> ids = new ArrayList<>();
        ids.add(parentId);
        List<Region> children = regionMapper.selectList(
                new LambdaQueryWrapper<Region>()
                        .eq(Region::getParentId, parentId));
        for (Region child : children) {
            ids.addAll(collectRegionIds(child.getId()));
        }
        return ids;
    }

    @Override
    public List<HotEnterpriseVO> getHotEnterprises(int limit) {
        if (limit <= 0) limit = 12;
        if (limit > 50) limit = 50;
        return enterpriseMapper.selectHotEnterprises(limit);
    }
}
