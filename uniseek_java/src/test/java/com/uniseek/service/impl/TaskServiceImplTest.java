package com.uniseek.service.impl;

import com.uniseek.common.PageResult;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dto.TaskVO;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;

/**
 * TaskServiceImpl 单元测试
 */
@RunWith(MockitoJUnitRunner.class)
public class TaskServiceImplTest {

    @Mock
    private TaskMapper taskMapper;

    private TaskServiceImpl taskService;

    @Before
    public void setUp() {
        taskService = new TaskServiceImpl();
        ReflectionTestUtils.setField(taskService, "taskMapper", taskMapper);
    }

    @Test
    public void getEnterpriseTasks_whenMultiEnterprise_shouldAggregateAllTasks() {
        // Given: 当前用户拥有多个企业记录（如驳回重提后的新旧记录）
        List<Long> enterpriseIds = Arrays.asList(11L, 22L);

        TaskVO taskFromEnterprise1 = new TaskVO();
        taskFromEnterprise1.setId(101L);
        taskFromEnterprise1.setEnterpriseId(11L);
        taskFromEnterprise1.setTitle("职位A");

        TaskVO taskFromEnterprise2 = new TaskVO();
        taskFromEnterprise2.setId(202L);
        taskFromEnterprise2.setEnterpriseId(22L);
        taskFromEnterprise2.setTitle("职位B");

        when(taskMapper.selectEnterpriseTasksByIds(anyList()))
                .thenReturn(Arrays.asList(taskFromEnterprise1, taskFromEnterprise2));

        // When: 查询多企业职位列表
        PageResult<TaskVO> result = taskService.getEnterpriseTasks(enterpriseIds);

        // Then: 应返回全部企业记录的职位
        assertNotNull(result);
        assertEquals(2, result.getTotal());
        assertEquals(2, result.getRecords().size());
        assertEquals(Long.valueOf(11L), result.getRecords().get(0).getEnterpriseId());
        assertEquals(Long.valueOf(22L), result.getRecords().get(1).getEnterpriseId());
    }

    @Test
    public void getEnterpriseTasks_whenNoEnterprise_shouldReturnEmpty() {
        // When: 传入空列表
        PageResult<TaskVO> result = taskService.getEnterpriseTasks(Collections.emptyList());

        // Then: 应返回空结果（不抛异常）
        assertNotNull(result);
        assertEquals(0, result.getTotal());
        assertEquals(0, result.getRecords().size());
    }

    @Test
    public void getEnterpriseTasks_whenNullEnterpriseIds_shouldReturnEmpty() {
        // When: 传入 null
        PageResult<TaskVO> result = taskService.getEnterpriseTasks((List<Long>) null);

        // Then: 应返回空结果（不抛异常）
        assertNotNull(result);
        assertEquals(0, result.getTotal());
        assertEquals(0, result.getRecords().size());
    }
}
