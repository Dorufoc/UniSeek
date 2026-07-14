package com.uniseek.service;

import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.dto.SendMessageRequest;

import java.util.List;

/**
 * 聊天服务接口
 */
public interface ChatService {

    /**
     * 获取当前用户的聊天会话列表
     *
     * @param userId 当前用户 ID
     * @param role   当前用户角色：0 求职者 / 1 HR
     * @return 会话列表（按最后消息时间倒序）
     */
    List<ChatSessionVO> getSessions(Long userId, Integer role);

    /**
     * 游标分页查询聊天历史消息
     *
     * @param applicationId 投递记录 ID（会话标识）
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param beforeId      游标 ID（上次加载的最小消息 ID，首次加载传 null）
     * @param pageSize      每页条数
     * @return 消息列表（按发送时间升序排列）
     */
    List<ChatMessageVO> getMessages(Long applicationId, Long userId, Integer role,
                                    Long beforeId, int pageSize);

    /**
     * 发送消息
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param request       发送消息请求
     * @return 发送的消息 VO
     */
    ChatMessageVO sendMessage(Long applicationId, Long userId, Integer role,
                              SendMessageRequest request);

    /**
     * 获取会话详情（含职位信息、投递状态、对方信息）
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @return 会话 VO
     */
    ChatSessionVO getSessionDetail(Long applicationId, Long userId, Integer role);

    /**
     * 标记会话中对方的消息为已读
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     */
    void markSessionRead(Long applicationId, Long userId);

    /**
     * 创建聊天会话（由 ApplicationService 在投递成功后调用）
     *
     * @param applicationId 投递记录 ID
     * @param employerId    企业方用户 ID（HR）
     * @param seekerId      求职者用户 ID
     */
    void createChatSession(Long applicationId, Long employerId, Long seekerId);
}