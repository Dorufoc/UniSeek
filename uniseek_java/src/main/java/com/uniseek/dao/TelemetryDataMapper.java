package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.TelemetryData;
import org.apache.ibatis.annotations.Mapper;

/**
 * 遥测数据 Mapper
 */
@Mapper
public interface TelemetryDataMapper extends BaseMapper<TelemetryData> {

}
