package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.uniseek.dao.DailyStatisticsMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.ResumeMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.DailyStatistics;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Resume;
import com.uniseek.entity.Task;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import com.uniseek.service.DailyStatisticsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 运营日报统计服务实现
 * 每日凌晨 2 点自动统计前一天的平台运营数据
 */
@Service
public class DailyStatisticsServiceImpl implements DailyStatisticsService {

    private static final Logger log = LoggerFactory.getLogger(DailyStatisticsServiceImpl.class);

    @Autowired
    private DailyStatisticsMapper dailyStatisticsMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private ResumeMapper resumeMapper;

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    /**
     * 每日凌晨 2 点执行统计任务
     */
    @Override
    @Scheduled(cron = "0 0 2 * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void collectDailyStatistics() {
        LocalDate statDate = LocalDate.now().minusDays(1);
        log.info("开始统计 {} 日平台运营数据", statDate);

        try {
            // 1. 新增用户数
            long newUserCount = userMapper.selectCount(
                    new QueryWrapper<User>().apply("DATE(create_time) = CURDATE() - 1"));

            // 2. 新增认证企业数（审核通过的企业）
            long newEnterpriseCount = enterpriseMapper.selectCount(
                    new QueryWrapper<Enterprise>().apply("DATE(audit_time) = CURDATE() - 1 AND audit_status = 1"));

            // 3. 新增职位数（审核通过的职位）
            long newTaskCount = taskMapper.selectCount(
                    new QueryWrapper<Task>().apply("DATE(audit_time) = CURDATE() - 1 AND status = 1"));

            // 4. 新增简历数
            long newResumeCount = resumeMapper.selectCount(
                    new QueryWrapper<Resume>().apply("DATE(create_time) = CURDATE() - 1"));

            // 5. 新增投递数
            long newDeliveryCount = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>().apply("DATE(create_time) = CURDATE() - 1"));

            // 6. 新增面试数（状态为待面试）
            long newInterviewCount = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>().apply("DATE(update_time) = CURDATE() - 1 AND status = 1"));

            // 7. 新增入职数（状态为已录用）
            long newEntryCount = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>().apply("DATE(update_time) = CURDATE() - 1 AND status = 3"));

            // 检查是否已存在该日期的统计记录，避免重复
            DailyStatistics existing = dailyStatisticsMapper.selectOne(
                    new QueryWrapper<DailyStatistics>().eq("stat_date", statDate));

            if (existing != null) {
                // 更新已有记录
                existing.setNewUserCount((int) newUserCount);
                existing.setNewEnterpriseCount((int) newEnterpriseCount);
                existing.setNewTaskCount((int) newTaskCount);
                existing.setNewResumeCount((int) newResumeCount);
                existing.setNewDeliveryCount((int) newDeliveryCount);
                existing.setNewInterviewCount((int) newInterviewCount);
                existing.setNewEntryCount((int) newEntryCount);
                dailyStatisticsMapper.updateById(existing);
                log.info("已更新 {} 日统计记录（ID: {}）", statDate, existing.getId());
            } else {
                // 新增统计记录
                DailyStatistics stats = new DailyStatistics();
                stats.setStatDate(statDate);
                stats.setNewUserCount((int) newUserCount);
                stats.setNewEnterpriseCount((int) newEnterpriseCount);
                stats.setNewTaskCount((int) newTaskCount);
                stats.setNewResumeCount((int) newResumeCount);
                stats.setNewDeliveryCount((int) newDeliveryCount);
                stats.setNewInterviewCount((int) newInterviewCount);
                stats.setNewEntryCount((int) newEntryCount);
                stats.setCreateTime(LocalDateTime.now());
                dailyStatisticsMapper.insert(stats);
                log.info("已新增 {} 日统计记录（ID: {}）", statDate, stats.getId());
            }

            log.info("{} 日统计完成：用户={}, 认证企业={}, 职位={}, 简历={}, 投递={}, 面试={}, 入职={}",
                    statDate, newUserCount, newEnterpriseCount, newTaskCount,
                    newResumeCount, newDeliveryCount, newInterviewCount, newEntryCount);
        } catch (Exception e) {
            log.error("统计 {} 日数据时发生异常", statDate, e);
        }
    }
}