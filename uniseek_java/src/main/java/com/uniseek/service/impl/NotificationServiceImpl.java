package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.dao.NotificationMapper;
import com.uniseek.entity.Notification;
import com.uniseek.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 通知服务实现
 */
@Service
public class NotificationServiceImpl implements NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Override
    public void sendNotification(Long receiverId, Long senderId, String title, String content,
                                  Integer type, Long bizId) {
        Notification notification = new Notification();
        notification.setReceiverId(receiverId);
        notification.setSenderId(senderId);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setType(type);
        notification.setIsRead(0);
        notification.setBizId(bizId);
        notification.setCreateTime(LocalDateTime.now());
        notificationMapper.insert(notification);
    }

    @Override
    public IPage<Notification> getUserNotifications(Long receiverId, Integer type, Integer isRead,
                                                      int page, int pageSize) {
        QueryWrapper<Notification> wrapper = new QueryWrapper<>();
        wrapper.eq("receiver_id", receiverId);
        if (type != null) {
            wrapper.eq("type", type);
        }
        if (isRead != null) {
            wrapper.eq("is_read", isRead);
        }
        wrapper.orderByDesc("create_time");
        return notificationMapper.selectPage(new Page<>(page, pageSize), wrapper);
    }

    @Override
    public Map<String, Integer> getUnreadCount(Long receiverId) {
        List<Map<String, Object>> list = notificationMapper.selectUnreadCountGroupByType(receiverId);

        int totalUnread = 0;
        int systemUnread = 0;
        int interviewUnread = 0;
        int offerUnread = 0;
        int rejectUnread = 0;

        for (Map<String, Object> item : list) {
            Object typeObj = item.get("type");
            Object countObj = item.get("count");
            if (typeObj == null || countObj == null) {
                continue;
            }
            int type = ((Number) typeObj).intValue();
            int count = ((Number) countObj).intValue();
            totalUnread += count;
            switch (type) {
                case 0:
                    systemUnread = count;
                    break;
                case 1:
                    interviewUnread = count;
                    break;
                case 2:
                    offerUnread = count;
                    break;
                case 3:
                    rejectUnread = count;
                    break;
                default:
                    break;
            }
        }

        Map<String, Integer> result = new HashMap<>();
        result.put("totalUnread", totalUnread);
        result.put("systemUnread", systemUnread);
        result.put("interviewUnread", interviewUnread);
        result.put("offerUnread", offerUnread);
        result.put("rejectUnread", rejectUnread);
        return result;
    }

    @Override
    public void markAsRead(Long id) {
        Notification notification = new Notification();
        notification.setId(id);
        notification.setIsRead(1);
        notificationMapper.updateById(notification);
    }

    @Override
    public int markAllAsRead(Long receiverId) {
        return notificationMapper.markAllAsRead(receiverId);
    }
}