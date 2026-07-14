package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 操作日志实体
 */
@Data
@TableName("operation_log")
public class OperationLog {

    /** 日志 ID */
    @TableId
    private Long id;

    /** 操作人 ID */
    private Long operatorId;

    /**
     * 操作类型，例如 REGISTER、LOGIN、SAVE_RESUME 等
     *
     * @see com.uniseek.constant.OperationType
     */
    private String operationType;

    /** 目标类型，例如 USER、RESUME、TASK 等 */
    private String targetType;

    /** 目标 ID */
    private String targetId;

    /** 操作详情（JSON 格式） */
    private String detail;

    /** 客户端 IP 地址 */
    private String ipAddress;

    /** 创建时间 */
    private LocalDateTime createTime;
}
