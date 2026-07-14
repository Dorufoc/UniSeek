package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天消息实体
 */
@Data
@TableName("chat_message")
public class ChatMessage {

    /** 消息 ID */
    @TableId
    private Long id;

    /** 会话 ID */
    private Long sessionId;

    /** 发送者用户 ID */
    private Long senderId;

    /** 消息类型：0 文本 / 1 图片 */
    private Integer messageType;

    /** 消息内容 */
    private String content;

    /** 是否已读：0 未读 / 1 已读 */
    private Integer isRead;

    /** 发送时间 */
    private LocalDateTime sendTime;
}