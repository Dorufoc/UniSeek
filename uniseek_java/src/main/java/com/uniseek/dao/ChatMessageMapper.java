package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.ChatMessage;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.util.List;

/**
 * 聊天消息 Mapper
 */
@Mapper
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {

    /**
     * 游标分页查询历史消息（按 id 降序，取小于 beforeId 的 pageSize 条）
     *
     * @param sessionId 会话 ID
     * @param beforeId  游标 ID（上次加载的最小消息 ID）
     * @param pageSize  每页条数
     * @return 消息列表（按 id 降序排列）
     */
    List<ChatMessage> selectMessagesBeforeId(@Param("sessionId") Long sessionId,
                                              @Param("beforeId") Long beforeId,
                                              @Param("pageSize") Integer pageSize);

    /**
     * 查询最新的一批消息（首次加载）
     *
     * @param sessionId 会话 ID
     * @param pageSize  每页条数
     * @return 消息列表（按 id 降序排列）
     */
    List<ChatMessage> selectLatestMessages(@Param("sessionId") Long sessionId,
                                            @Param("pageSize") Integer pageSize);

    /**
     * 统计会话中某个用户的未读消息数
     *
     * @param sessionId 会话 ID
     * @param userId    当前用户 ID（排除自己的消息）
     * @return 未读消息数
     */
    Integer countUnread(@Param("sessionId") Long sessionId, @Param("userId") Long userId);

    /**
     * 标记会话中对方发送的消息为已读
     *
     * @param sessionId 会话 ID
     * @param userId    当前用户 ID
     * @return 受影响行数
     */
    @Update("UPDATE chat_message SET is_read = 1 WHERE session_id = #{sessionId} AND sender_id != #{userId} AND is_read = 0")
    Integer markAsRead(@Param("sessionId") Long sessionId, @Param("userId") Long userId);
}