package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.uniseek.dao.TelemetryDataMapper;
import com.uniseek.dto.LatestTelemetryResponse;
import com.uniseek.dto.TelemetryRequest;
import com.uniseek.entity.TelemetryData;
import com.uniseek.service.TelemetryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 遥测数据服务实现
 */
@Service
public class TelemetryServiceImpl implements TelemetryService {

    @Autowired
    private TelemetryDataMapper telemetryDataMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void report(TelemetryRequest request) {
        TelemetryData data = new TelemetryData();
        data.setTemperature(request.getTemperature());
        data.setHumidity(request.getHumidity());
        data.setReportTime(LocalDateTime.now());
        data.setCreateTime(LocalDateTime.now());
        telemetryDataMapper.insert(data);
    }

    @Override
    public LatestTelemetryResponse getLatest() {
        // 按上报时间倒序、主键倒序确定最新一条记录
        QueryWrapper<TelemetryData> wrapper = new QueryWrapper<>();
        wrapper.orderByDesc("report_time", "id").last("limit 1");
        TelemetryData data = telemetryDataMapper.selectOne(wrapper);
        if (data == null) {
            return null;
        }
        return new LatestTelemetryResponse(
                data.getTemperature(),
                data.getHumidity(),
                data.getReportTime()
        );
    }
}
