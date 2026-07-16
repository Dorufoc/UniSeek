package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 职位任务实体
 */
@Data
@TableName("task")
public class Task {

    /** 职位 ID */
    @TableId
    private Long id;

    /** 所属企业 ID */
    private Long enterpriseId;

    /** 职位分类 ID */
    private Long categoryId;

    /** 地区 ID */
    private Long regionId;

    /** 职位标题 */
    private String title;

    /** 职位描述 */
    private String description;

    /** 最低薪资（元） */
    private BigDecimal salaryMin;

    /** 最高薪资（元） */
    private BigDecimal salaryMax;

    /** 薪资单位：0 日结 / 1 时薪 / 2 月结 */
    private Integer salaryUnit;

    /** 工作类型：1 全职 / 2 兼职 / 3 实习 */
    private Integer jobType;

    /** 招聘总名额 */
    private Integer totalQuota;

    /** 剩余名额 */
    private Integer remainingQuota;

    /** 工作地址 */
    private String address;

    /** 发布企业名称（非数据库字段，关联查询填充） */
    @TableField(exist = false)
    private String enterpriseName;

    /** 职位标签，JSON数组格式 */
    @TableField("tag")
    private String tag;

    /** 经度 */
    private BigDecimal longitude;

    /** 纬度 */
    private BigDecimal latitude;

    /** 状态：0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架 */
    private Integer status;

    /** 驳回原因 */
    private String rejectReason;

    /** 乐观锁版本号 */
    @Version
    private Integer version;

    /** 报名截止时间 */
    private LocalDateTime deadline;

    /** 审核通过时间 */
    @TableField("audit_time")
    private LocalDateTime auditTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
