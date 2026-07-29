package com.uniseek.task.schedule;

import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.entity.Task;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/** 职位定时状态处理测试。 */
@RunWith(MockitoJUnitRunner.class)
public class TaskScheduledServiceTest {

    @Mock
    private TaskMapper taskMapper;

    private TaskScheduledService scheduledService;

    @Before
    public void setUp() {
        scheduledService = new TaskScheduledService();
        ReflectionTestUtils.setField(scheduledService, "taskMapper", taskMapper);
        when(taskMapper.update(any(Task.class), any(UpdateWrapper.class))).thenReturn(1);
    }

    @Test
    public void shouldMarkExpiredAndFullTasksWithDistinctStatuses() {
        scheduledService.expireOverdueTasks();

        ArgumentCaptor<Task> captor = ArgumentCaptor.forClass(Task.class);
        org.mockito.Mockito.verify(taskMapper, org.mockito.Mockito.times(2))
                .update(captor.capture(), any(UpdateWrapper.class));
        List<Task> updates = captor.getAllValues();

        assertEquals(Integer.valueOf(3), updates.get(0).getStatus());
        assertEquals(Integer.valueOf(2), updates.get(1).getStatus());
    }
}
