package com.uniseek.service.impl;

import com.uniseek.dao.TelemetryDataMapper;
import com.uniseek.dto.LatestTelemetryResponse;
import com.uniseek.entity.TelemetryData;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * TelemetryServiceImpl 单元测试
 */
@RunWith(MockitoJUnitRunner.class)
public class TelemetryServiceImplTest {

    @Mock
    private TelemetryDataMapper telemetryDataMapper;

    private TelemetryServiceImpl telemetryService;

    @Before
    public void setUp() {
        telemetryService = new TelemetryServiceImpl();
        ReflectionTestUtils.setField(telemetryService, "telemetryDataMapper", telemetryDataMapper);
    }

    @Test
    public void getLatest_whenDataExists_shouldReturnLatestTelemetryResponse() {
        LocalDateTime reportTime = LocalDateTime.of(2026, 7, 29, 14, 30, 0);
        TelemetryData data = new TelemetryData();
        data.setId(1L);
        data.setTemperature(26.5);
        data.setHumidity(68.0);
        data.setReportTime(reportTime);
        when(telemetryDataMapper.selectOne(any())).thenReturn(data);

        LatestTelemetryResponse result = telemetryService.getLatest();

        assertNotNull(result);
        assertEquals(Double.valueOf(26.5), result.getTemperature());
        assertEquals(Double.valueOf(68.0), result.getHumidity());
        assertEquals(reportTime, result.getReportTime());
        verify(telemetryDataMapper).selectOne(any());
    }

    @Test
    public void getLatest_whenNoData_shouldReturnNull() {
        when(telemetryDataMapper.selectOne(any())).thenReturn(null);

        LatestTelemetryResponse result = telemetryService.getLatest();

        assertNull(result);
    }
}
