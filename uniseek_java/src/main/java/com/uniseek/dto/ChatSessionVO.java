package com.uniseek.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天会话视图 VO
 */
@Data
public class ChatSessionVO {

    /** 投递记录 ID（即会话关联 ID） */
    private Long applicationId;

    /** 职位 ID */
    private Long taskId;

    /** 职位标题 */
    private String taskTitle;

    /** 职位状态：0 待审核 / 1 已发布 / 2 进行中 / 3 已截止 / 4 已下架 */
    private Integer taskStatus;

    /** 投递状态：0 已投递 / 1 待面试 / 2 面试通过 / 3 已录用 / 4 已淘汰 / 5 已完成 */
    private Integer applicationStatus;

    /** 对方用户 ID */
    private Long counterpartId;

    /** 对方用户昵称 */
    private String counterpartName;

    /** 对方头像 URL */
    private String counterpartAvatar;

    /** 最后一条消息内容 */
    private String lastMessage;

    /** 最后一条消息时间 */
    private LocalDateTime lastMessageTime;

    /** 未读消息数 */
    private Integer unreadCount;
}
