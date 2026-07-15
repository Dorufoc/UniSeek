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
     * 每小时执行一次，将已过期且状态为"招聘中"的职位自动变为"已过期"，
     * 同时将剩余名额为 0 但状态仍为招聘中的职位标记为"已满员"
     */
    @Scheduled(cron = "0 0 * * * ?")
    public void expireOverdueTasks() {
        log.info("开始执行职位到期定时任务...");

        // 处理过期职位
        Task updateEntity = new Task();
        updateEntity.setStatus(3);
        updateEntity.setUpdateTime(LocalDateTime.now());

        int expiredCount = taskMapper.update(updateEntity,
                new UpdateWrapper<Task>()
                        .eq("status", 1)
                        .isNotNull("deadline")
                        .lt("deadline", LocalDateTime.now()));

        log.info("职位到期处理完毕，共更新 {} 条过期职位", expiredCount);

        // 处理名额已满的职位：remaining_quota = 0 但 status 仍为 1 的职位自动下架
        Task fullEntity = new Task();
        fullEntity.setStatus(4);
        fullEntity.setUpdateTime(LocalDateTime.now());

        int fullCount = taskMapper.update(fullEntity,
                new UpdateWrapper<Task>()
                        .eq("status", 1)
                        .eq("remaining_quota", 0));

        log.info("职位满员自动下架处理完毕，共更新 {} 条职位", fullCount);
    }
}
