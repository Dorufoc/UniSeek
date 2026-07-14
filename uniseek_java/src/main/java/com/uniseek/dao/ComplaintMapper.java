package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.Complaint;
import org.apache.ibatis.annotations.Mapper;

/**
 * 投诉 Mapper
 */
@Mapper
public interface ComplaintMapper extends BaseMapper<Complaint> {

}
