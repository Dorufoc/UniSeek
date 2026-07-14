package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 投递申请实体
 */
@Data
@TableName("task_application")
public class TaskApplication {

    /** 投递记录 ID */
    @TableId
    private Long id;

    /** 职位 ID */
    private Long taskId;

    /** 求职者 ID */
    private Long applicantId;

    /** 简历快照（JSON 字符串） */
    private String resumeSnapshot;

    /** 附件简历 URL */
    private String attachmentUrl;

    /** 状态：0 已投递 / 1 待面试 / 2 待定 / 3 已录用 / 4 已淘汰 / 5 已完成 */
    private Integer status;

    /** HR 用户 ID（处理者） */
    private Long hrId;

    /** 面试时间 */
    private LocalDateTime interviewTime;

    /** 面试地点 */
    private String interviewLocation;

    /** 淘汰原因 */
    private String rejectReason;

    /** HR 备注 */
    private String hrNote;

    /** 乐观锁版本号 */
    @Version
    private Integer version;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}