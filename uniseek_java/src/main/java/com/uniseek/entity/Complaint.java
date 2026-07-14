package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 投诉实体
 */
@Data
@TableName("complaint")
public class Complaint {

    /** 投诉 ID */
    @TableId
    private Long id;

    /** 投诉人 ID */
    private Long complainantId;

    /** 被投诉对象类型：1 企业 / 2 用户 */
    private Integer targetType;

    /** 被投诉对象 ID */
    private Long targetId;

    /** 投诉类型 */
    private Integer type;

    /** 投诉内容 */
    private String content;

    /** 处理状态：0 待处理 / 1 处理中 / 2 已结案，默认 0 */
    private Integer status;

    /** 处理人 ID */
    private Long handlerId;

    /** 处理结果 */
    private String handleResult;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
