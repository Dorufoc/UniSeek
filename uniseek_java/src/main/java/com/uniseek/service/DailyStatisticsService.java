package com.uniseek.service;

/**
 * 运营日报统计服务接口
 */
public interface DailyStatisticsService {

    /**
     * 执行每日统计任务
     * 统计前一天的平台运营数据并持久化
     */
    void collectDailyStatistics();
}