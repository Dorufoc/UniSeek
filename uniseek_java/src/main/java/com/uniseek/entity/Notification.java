package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 通知消息实体
 */
@Data
@TableName("notification")
public class Notification {

    /** 消息 ID */
    @TableId
    private Long id;

    /** 接收者 ID */
    private Long receiverId;

    /** 发送者 ID */
    private Long senderId;

    /** 发送者名称（非数据库字段，由 Service 填充） */
    @TableField(exist = false)
    private String senderName;

    /** 消息标题 */
    private String title;

    /** 消息内容 */
    private String content;

    /** 消息类型：0 系统通知 / 1 面试邀请 / 2 录用通知 / 3 淘汰通知 */
    private Integer type;

    /** 是否已读：0 未读 / 1 已读 */
    private Integer isRead;

    /** 业务关联 ID（如任务 ID、投递 ID 等） */
    private Long bizId;

    /** 创建时间 */
    private LocalDateTime createTime;
}