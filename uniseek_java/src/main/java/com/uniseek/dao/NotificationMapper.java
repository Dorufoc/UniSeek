package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.Notification;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 通知 Mapper
 */
@Mapper
public interface NotificationMapper extends BaseMapper<Notification> {

    /**
     * 查询未读消息按类型分组统计
     *
     * @param receiverId 接收者 ID
     * @return 每组 type -> count 的 Map 列表
     */
    List<Map<String, Object>> selectUnreadCountGroupByType(@Param("receiverId") Long receiverId);

    /**
     * 将接收者的所有未读消息标记为已读
     *
     * @param receiverId 接收者 ID
     * @return 影响的行数
     */
    int markAllAsRead(@Param("receiverId") Long receiverId);
}