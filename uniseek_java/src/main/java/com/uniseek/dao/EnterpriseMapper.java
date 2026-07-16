package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.dto.HotEnterpriseVO;
import com.uniseek.entity.Enterprise;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 企业资质认证 Mapper
 */
@Mapper
public interface EnterpriseMapper extends BaseMapper<Enterprise> {

    List<HotEnterpriseVO> selectHotEnterprises(@Param("limit") int limit);

    /**
     * 分页查询已认证企业，支持关键词/行业/地区筛选和排序
     *
     * @param page      分页对象
     * @param keyword   关键词（模糊匹配企业名称）
     * @param industry  行业（精确匹配）
     * @param regionIds 地区ID列表（含子级）
     * @param sortBy    排序字段：jobCount / avgSalary / default（创建时间）
     * @param sortOrder 排序方向：asc / desc
     * @return 分页企业列表
     */
    IPage<Enterprise> selectEnterprisePage(
            Page<?> page,
            @Param("keyword") String keyword,
            @Param("industry") String industry,
            @Param("regionIds") List<Long> regionIds,
            @Param("sortBy") String sortBy,
            @Param("sortOrder") String sortOrder
    );
}
