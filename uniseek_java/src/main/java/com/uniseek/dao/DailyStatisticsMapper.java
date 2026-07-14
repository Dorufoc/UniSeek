package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.DailyStatistics;
import org.apache.ibatis.annotations.Mapper;

/**
 * 运营日报统计 Mapper
 */
@Mapper
public interface DailyStatisticsMapper extends BaseMapper<DailyStatistics> {

}