package com.uniseek.user.service.impl;

import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Task;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/** 用户统计服务测试。 */
@RunWith(MockitoJUnitRunner.class)
public class UserServiceImplTest {

    @Mock
    private EnterpriseMapper enterpriseMapper;

    @Mock
    private TaskMapper taskMapper;

    @Mock
    private TaskApplicationMapper taskApplicationMapper;

    private UserServiceImpl userService;

    @Before
    public void setUp() {
        userService = new UserServiceImpl();
        ReflectionTestUtils.setField(userService, "enterpriseMapper", enterpriseMapper);
        ReflectionTestUtils.setField(userService, "taskMapper", taskMapper);
        ReflectionTestUtils.setField(userService, "taskApplicationMapper", taskApplicationMapper);
    }

    @Test
    public void shouldAggregateRecruiterStatsAcrossAllEnterpriseRecords() {
        Enterprise rejectedEnterprise = new Enterprise();
        rejectedEnterprise.setId(11L);
        Enterprise activeEnterprise = new Enterprise();
        activeEnterprise.setId(22L);
        List<Enterprise> enterprises = Arrays.asList(rejectedEnterprise, activeEnterprise);

        Task firstTask = new Task();
        firstTask.setId(101L);
        Task secondTask = new Task();
        secondTask.setId(202L);
        List<Task> tasks = Arrays.asList(firstTask, secondTask);

        when(enterpriseMapper.selectList(any())).thenReturn(enterprises);
        when(taskMapper.selectList(any())).thenReturn(tasks);
        when(taskApplicationMapper.selectCount(any())).thenReturn(5, 2);

        Map<String, Object> stats = userService.getUserStats(7L, 1);

        assertEquals(5, stats.get("receivedResumes"));
        assertEquals(2, stats.get("hired"));
    }
}
