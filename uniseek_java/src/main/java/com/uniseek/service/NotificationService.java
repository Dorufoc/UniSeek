package com.uniseek.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.uniseek.entity.Notification;

import java.util.Map;

/**
 * 通知服务接口
 */
public interface NotificationService {

    /**
     * 发送通知
     *
     * @param receiverId 接收者 ID
     * @param senderId   发送者 ID
     * @param title      标题
     * @param content    内容
     * @param type       类型：0 系统通知 / 1 面试邀请 / 2 录用通知 / 3 淘汰通知
     * @param bizId      业务关联 ID
     */
    void sendNotification(Long receiverId, Long senderId, String title, String content,
                          Integer type, Long bizId);

    /**
     * 获取用户通知（分页）
     *
     * @param receiverId 接收者 ID
     * @param type       类型筛选（可为 null）
     * @param isRead     已读状态筛选（可为 null）
     * @param page       页码
     * @param pageSize   每页条数
     * @return 分页结果
     */
    IPage<Notification> getUserNotifications(Long receiverId, Integer type, Integer isRead,
                                              int page, int pageSize);

    /**
     * 获取未读消息数（按类型分组）
     *
     * @param receiverId 接收者 ID
     * @return 包含 totalUnread / systemUnread / interviewUnread / offerUnread / rejectUnread 的 Map
     */
    Map<String, Integer> getUnreadCount(Long receiverId);

    /**
     * 标记单条消息为已读
     *
     * @param id 消息 ID
     */
    void markAsRead(Long id);

    /**
     * 将接收者的所有未读消息标记为已读
     *
     * @param receiverId 接收者 ID
     * @return 被影响的消息数量
     */
    int markAllAsRead(Long receiverId);
}