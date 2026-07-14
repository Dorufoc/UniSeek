package com.uniseek.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.entity.Notification;
import com.uniseek.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 消息通知控制器
 */
@RestController
@RequestMapping("/api/messages")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    /**
     * 消息列表（分页）
     */
    @GetMapping
    public ApiResult<PageResult<Notification>> getUserNotifications(
            @RequestParam(required = false) Integer type,
            @RequestParam(required = false) Integer isRead,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        Long receiverId = UserContext.getUserId();
        IPage<Notification> pageResult = notificationService.getUserNotifications(
                receiverId, type, isRead, page, pageSize);
        return ApiResult.success(PageResult.of(pageResult));
    }

    /**
     * 未读消息数
     */
    @GetMapping("/unread-count")
    public ApiResult<Map<String, Integer>> getUnreadCount() {
        Long receiverId = UserContext.getUserId();
        Map<String, Integer> unreadCount = notificationService.getUnreadCount(receiverId);
        return ApiResult.success(unreadCount);
    }

    /**
     * 标记单条消息为已读
     */
    @PutMapping("/{id}/read")
    public ApiResult<Void> markAsRead(@PathVariable Long id) {
        notificationService.markAsRead(id);
        return ApiResult.success(null);
    }

    /**
     * 全部标记已读
     */
    @PutMapping("/read-all")
    public ApiResult<Map<String, Integer>> markAllAsRead() {
        Long receiverId = UserContext.getUserId();
        int affectedCount = notificationService.markAllAsRead(receiverId);
        Map<String, Integer> data = new HashMap<>();
        data.put("affectedCount", affectedCount);
        return ApiResult.success("全部消息已标记为已读", data);
    }
}