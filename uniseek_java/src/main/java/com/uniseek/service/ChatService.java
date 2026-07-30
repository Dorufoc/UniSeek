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
     * @param sessionId     会话标识：投递会话时为 task_application_id，直接会话时为 chat_session.id
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param beforeId      游标 ID（上次加载的最小消息 ID，首次加载传 null）
     * @param pageSize      每页条数
     * @param sessionType   会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 消息列表（按发送时间升序排列）
     */
    List<ChatMessageVO> getMessages(Long sessionId, Long userId, Integer role,
                                      Long beforeId, int pageSize, String sessionType);

    /**
     * 发送消息
     *
     * @param sessionId     会话标识：投递会话时为 task_application_id，直接会话时为 chat_session.id
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param request       发送消息请求
     * @param sessionType   会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 发送的消息 VO
     */
    ChatMessageVO sendMessage(Long sessionId, Long userId, Integer role,
                              SendMessageRequest request, String sessionType);

    /**
     * 获取会话详情（含职位信息、投递状态、对方信息）
     *
     * @param sessionId     会话标识：投递会话时为 task_application_id，直接会话时为 chat_session.id
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param sessionType   会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 会话 VO
     */
    ChatSessionVO getSessionDetail(Long sessionId, Long userId, Integer role, String sessionType);

    /**
     * 标记会话中对方的消息为已读
     *
     * @param sessionId     会话标识：投递会话时为 task_application_id，直接会话时为 chat_session.id
     * @param userId        当前用户 ID
     * @param sessionType   会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     */
    void markSessionRead(Long sessionId, Long userId, String sessionType);

    /**
     * 创建聊天会话（由 ApplicationService 在投递成功后调用）
     *
     * @param applicationId 投递记录 ID
     * @param employerId    企业方用户 ID（HR）
     * @param seekerId      求职者用户 ID
     */
    void createChatSession(Long applicationId, Long employerId, Long seekerId);

    /**
     * 创建直接会话（人才库联系求职者，无需投递记录）
     *
     * @param employerId HR 用户 ID
     * @param seekerId   求职者用户 ID
     * @return 会话 ID
     */
    Long createDirectSession(Long employerId, Long seekerId);

    /**
     * 确保投递记录存在聊天会话（不存在时自动创建）
     * <p>由 HR 在首页点击「联系」时调用，保证会话就绪后跳转</p>
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     */
    void initChatSession(Long applicationId, Long userId, Integer role);

    /**
     * 获取当前用户所有会话中的未读消息总数
     */
    Long getUnreadCount(Long userId);

    /**
     * 发送系统状态变更聊天消息（自动模拟 HR 发送）
     * <p>由 ApplicationService 在求职状态变更时调用，向求职者推送状态变更提示消息。</p>
     *
     * @param applicationId 投递记录 ID
     * @param hrUserId      发送者（HR）用户 ID
     * @param content       消息内容（差异化文案）
     * @return 发送的消息 VO
     */
    ChatMessageVO sendStatusChangeSystemMessage(Long applicationId, Long hrUserId, String content);
}