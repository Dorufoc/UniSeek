package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 聊天会话实体
 */
@Data
@TableName("chat_session")
public class ChatSession {

    /** 会话 ID */
    @TableId
    private Long id;

    /** 关联的投递记录 ID */
    private Long taskApplicationId;

    /** 企业方用户 ID（HR） */
    private Long employerId;

    /** 求职者用户 ID */
    private Long seekerId;

    /** 最后一条消息内容 */
    private String lastMessage;

    /** 最后一条消息时间 */
    private LocalDateTime lastMessageTime;

    /** 会话状态：0 正常 / 1 关闭 */
    private Integer status;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}