package com.uniseek.task.schedule;

import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.entity.Task;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 职位定时任务
 * <p>
 * 负责自动处理职位相关的定时操作，如到期自动下架等。
 */
@Component
public class TaskScheduledService {

    private static final Logger log = LoggerFactory.getLogger(TaskScheduledService.class);

    @Autowired
    private TaskMapper taskMapper;

    /**
     * 每小时执行一次，将已过期且状态为"已发布"的职位自动变为"已截止"
     * <p>
     * 执行条件：status = 1（已发布） AND deadline IS NOT NULL AND deadline < NOW()
     * 更新内容：status = 3（已截止），update_time = NOW()
     */
    @Scheduled(cron = "0 0 * * * ?")
    public void expireOverdueTasks() {
        log.info("开始执行职位到期定时任务...");

        Task updateEntity = new Task();
        updateEntity.setStatus(3);

        int updatedCount = taskMapper.update(updateEntity,
                new UpdateWrapper<Task>()
                        .eq("status", 1)
                        .isNotNull("deadline")
                        .lt("deadline", LocalDateTime.now()));

        log.info("职位到期定时任务执行完毕，共更新 {} 条过期职位", updatedCount);
    }
}
