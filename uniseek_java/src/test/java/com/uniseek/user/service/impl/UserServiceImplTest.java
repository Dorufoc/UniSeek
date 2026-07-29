package com.uniseek.user.service.impl;

import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.FavoriteMapper;
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
import java.util.Collections;
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

    @Mock
    private FavoriteMapper favoriteMapper;

    private UserServiceImpl userService;

    @Before
    public void setUp() {
        userService = new UserServiceImpl();
        ReflectionTestUtils.setField(userService, "enterpriseMapper", enterpriseMapper);
        ReflectionTestUtils.setField(userService, "taskMapper", taskMapper);
        ReflectionTestUtils.setField(userService, "taskApplicationMapper", taskApplicationMapper);
        ReflectionTestUtils.setField(userService, "favoriteMapper", favoriteMapper);
    }

    @Test
    public void shouldReturnAllRecruiterFieldsWhenMultipleEnterprises() {
        // 准备：两个企业（一个已驳回、一个已认证）
        Enterprise rejectedEnterprise = new Enterprise();
        rejectedEnterprise.setId(11L);
        Enterprise activeEnterprise = new Enterprise();
        activeEnterprise.setId(22L);
        List<Enterprise> enterprises = Arrays.asList(rejectedEnterprise, activeEnterprise);

        // 准备：两个职位
        Task firstTask = new Task();
        firstTask.setId(101L);
        Task secondTask = new Task();
        secondTask.setId(202L);
        List<Task> tasks = Arrays.asList(firstTask, secondTask);

        when(enterpriseMapper.selectList(any())).thenReturn(enterprises);
        when(taskMapper.selectCount(any())).thenReturn(3);  // activeJobs = 3
        when(taskMapper.selectList(any())).thenReturn(tasks);
        // 四次 selectCount 依次：receivedResumes=5, interviews=3, pending=2, hired=4
        when(taskApplicationMapper.selectCount(any())).thenReturn(5, 3, 2, 4);

        Map<String, Object> stats = userService.getUserStats(7L, 1);

        assertEquals("收到简历总数应跨企业聚合", 5, stats.get("receivedResumes"));
        assertEquals("待面试数应为 status=1", 3, stats.get("interviews"));
        assertEquals("待定数应为 status=2", 2, stats.get("pending"));
        assertEquals("招聘中职位数应为 status=1", 3, stats.get("activeJobs"));
        assertEquals("已录用数应为 status=3", 4, stats.get("hired"));
    }

    @Test
    public void shouldReturnZeroWhenNoEnterprises() {
        when(enterpriseMapper.selectList(any())).thenReturn(Collections.emptyList());

        Map<String, Object> stats = userService.getUserStats(7L, 1);

        assertEquals(0, stats.get("receivedResumes"));
        assertEquals(0, stats.get("interviews"));
        assertEquals(0, stats.get("pending"));
        assertEquals(0, stats.get("activeJobs"));
        assertEquals(0, stats.get("hired"));
    }

    @Test
    public void shouldReturnZeroWhenEnterprisesHaveNoTasks() {
        Enterprise enterprise = new Enterprise();
        enterprise.setId(11L);
        List<Enterprise> enterprises = Collections.singletonList(enterprise);

        when(enterpriseMapper.selectList(any())).thenReturn(enterprises);
        when(taskMapper.selectCount(any())).thenReturn(0);  // activeJobs = 0
        when(taskMapper.selectList(any())).thenReturn(Collections.emptyList());

        Map<String, Object> stats = userService.getUserStats(7L, 1);

        assertEquals(0, stats.get("receivedResumes"));
        assertEquals(0, stats.get("interviews"));
        assertEquals(0, stats.get("pending"));
        assertEquals(0, stats.get("activeJobs"));
        assertEquals(0, stats.get("hired"));
    }

    @Test
    public void shouldPreserveExistingSeekerStatsBehavior() {
        when(taskApplicationMapper.selectCount(any())).thenReturn(10, 4);
        when(favoriteMapper.selectCount(any())).thenReturn(7);

        Map<String, Object> stats = userService.getUserStats(7L, 0);

        assertEquals(10, stats.get("applications"));
        assertEquals(4, stats.get("interviews"));
        assertEquals(7, stats.get("favorites"));
        // 求职者不包含招聘者字段
        assertEquals(null, stats.get("receivedResumes"));
        assertEquals(null, stats.get("pending"));
        assertEquals(null, stats.get("activeJobs"));
        assertEquals(null, stats.get("hired"));
    }
}
