package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 运营日报统计实体
 */
@Data
@TableName("daily_statistics")
public class DailyStatistics {

    /** 统计 ID */
    @TableId
    private Long id;

    /** 统计日期 */
    private LocalDate statDate;

    /** 新增用户数 */
    private Integer newUserCount;

    /** 新增认证企业数 */
    private Integer newEnterpriseCount;

    /** 新增职位数 */
    private Integer newTaskCount;

    /** 新增简历数 */
    private Integer newResumeCount;

    /** 新增投递数 */
    private Integer newDeliveryCount;

    /** 新增面试数 */
    private Integer newInterviewCount;

    /** 新增入职数 */
    private Integer newEntryCount;

    /** 创建时间 */
    private LocalDateTime createTime;
}