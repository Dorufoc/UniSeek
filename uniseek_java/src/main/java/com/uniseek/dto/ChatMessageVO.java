package com.uniseek.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天消息视图 VO
 */
@Data
public class ChatMessageVO {

    /** 消息 ID */
    private Long id;

    /** 发送者用户 ID */
    private Long senderId;

    /** 发送者昵称 */
    private String senderName;

    /** 发送者头像 */
    private String senderAvatar;

    /** 消息类型：0 文本 / 1 图片 / 2 简历附件 */
    private Integer messageType;

    /** 消息内容 */
    private String content;

    /** 是否已读：0 未读 / 1 已读 */
    private Integer isRead;

    /** 发送时间 */
    private LocalDateTime sendTime;
}
