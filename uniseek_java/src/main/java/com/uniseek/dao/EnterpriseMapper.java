package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
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
}
