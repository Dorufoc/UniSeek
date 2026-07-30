package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.uniseek.chat.ChatSessionType;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ChatMessageMapper;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.ResumeMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.dto.SendMessageRequest;
import com.uniseek.entity.ChatMessage;
import com.uniseek.entity.ChatSession;
import com.uniseek.entity.Resume;
import com.uniseek.entity.Task;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import com.uniseek.chat.websocket.ChatWebSocketHandler;
import com.uniseek.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 聊天服务实现
 */
@Service
public class ChatServiceImpl implements ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatServiceImpl.class);

    @Autowired
    private ChatSessionMapper chatSessionMapper;

    @Autowired
    private ChatMessageMapper chatMessageMapper;

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ResumeMapper resumeMapper;

    @Autowired
    private ChatWebSocketHandler chatWebSocketHandler;

    @Override
    public List<ChatSessionVO> getSessions(Long userId, Integer role) {
        List<ChatSessionVO> sessions;
        if (role == 1) {
            sessions = chatSessionMapper.selectSessionsByEmployer(userId);
            List<ChatSessionVO> direct = chatSessionMapper.selectDirectSessionsByEmployer(userId);
            if (direct != null && !direct.isEmpty()) {
                if (sessions == null) sessions = direct;
                else sessions.addAll(direct);
            }
        } else {
            sessions = chatSessionMapper.selectSessionsBySeeker(userId);
            List<ChatSessionVO> direct = chatSessionMapper.selectDirectSessionsBySeeker(userId);
            if (direct != null && !direct.isEmpty()) {
                if (sessions == null) sessions = direct;
                else sessions.addAll(direct);
            }
        }
        // 合并职位投递会话与直接会话后，统一按最后消息时间倒序排序
        if (sessions != null) {
            sessions.sort((a, b) -> {
                LocalDateTime t1 = a.getLastMessageTime();
                LocalDateTime t2 = b.getLastMessageTime();
                if (t1 == null && t2 == null) return 0;
                if (t1 == null) return 1;
                if (t2 == null) return -1;
                return t2.compareTo(t1);
            });
        }
        return sessions != null ? sessions : Collections.emptyList();
    }

    @Override
    public List<ChatMessageVO> getMessages(Long sessionId, Long userId, Integer role,
                                           Long beforeId, int pageSize, String sessionType) {
        // 1. 权限校验
        ChatSession session = validateSessionAccess(sessionId, userId, role, sessionType);

        // 2. 查询消息（标记已读由 markSessionRead 显式处理，避免翻页加载历史时清除未读状态）
        Long realSessionId = session.getId();

        // 3. 查询消息
        List<ChatMessage> messages;
        if (beforeId == null || beforeId <= 0) {
            // 首次加载，取最新 pageSize 条
            messages = chatMessageMapper.selectLatestMessages(realSessionId, pageSize);
        } else {
            // 游标分页，取小于 beforeId 的 pageSize 条
            messages = chatMessageMapper.selectMessagesBeforeId(realSessionId, beforeId, pageSize);
        }

        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }

        // DB 按 id 降序返回（最新在前），直接保留该顺序

        // 5. 组装 VO（批量查询发送者信息）
        List<ChatMessageVO> voList = new ArrayList<>(messages.size());
        for (ChatMessage msg : messages) {
            ChatMessageVO vo = buildChatMessageVO(msg);
            voList.add(vo);
        }
        return voList;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ChatMessageVO sendMessage(Long sessionId, Long userId, Integer role,
                                     SendMessageRequest request, String sessionType) {
        // 1. 权限校验
        ChatSession session = validateSessionAccess(sessionId, userId, role, sessionType);

        // 2. 求职者限制：HR 未回复前只能发送一条消息
        if (role == 0 && !computeCanSend(session, userId, role)) {
            throw new BusinessException("HR 未回复前，您只能发送一条消息");
        }

        // 3. 校验消息类型
        Integer messageType = request.getMessageType();
        if (messageType == null) {
            messageType = 0;
        }
        if (messageType == 2) {
            // 简历附件：仅求职者可发送，后端获取简历附件 URL
            if (role != 0) {
                throw new BusinessException("仅求职者可发送简历附件");
            }
            if (!session.getSeekerId().equals(userId)) {
                throw new BusinessException("无权发送简历");
            }
            String resumeUrl = getSeekerResumeUrl(userId);
            if (resumeUrl == null) {
                throw new BusinessException("暂无简历附件，请先上传简历文件");
            }
            request.setContent(resumeUrl);
        } else if (messageType != 0 && messageType != 1) {
            throw new BusinessException("消息类型不合法：0 文本 / 1 图片 / 2 简历附件");
        }

        // 4. 插入消息
        Long realSessionId = session.getId();
        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSessionId(realSessionId);
        chatMessage.setSenderId(userId);
        chatMessage.setMessageType(messageType);
        chatMessage.setContent(request.getContent());
        chatMessage.setIsRead(0);
        chatMessage.setSendTime(LocalDateTime.now());
        chatMessageMapper.insert(chatMessage);

        // 5. 更新会话的最后消息
        String preview;
        if (messageType == 2) {
            preview = "[简历附件]";
        } else if (messageType == 1) {
            preview = "[图片]";
        } else {
            preview = request.getContent();
        }
        session.setLastMessage(preview);
        session.setLastMessageTime(chatMessage.getSendTime());
        session.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.updateById(session);

        // 6. 返回 VO
        return buildChatMessageVO(chatMessage);
    }

    @Override
    public ChatSessionVO getSessionDetail(Long sessionId, Long userId, Integer role, String sessionType) {
        if (sessionId == null || sessionId == 0) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 直接会话：传入的 sessionId 即 chat_session.id，按主键直接查询并校验参与者身份
        if (ChatSessionType.isDirect(sessionType)) {
            ChatSession session = chatSessionMapper.selectById(sessionId);
            if (session == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
            }
            validateParticipant(session, userId, role);
            return buildDirectSessionVO(session, userId, role);
        }

        // 投递会话：通过 task_application_id 解析会话，避免 chat_session.id 与投递 ID 重叠
        ChatSessionVO vo = chatSessionMapper.selectSessionDetail(sessionId, userId, role);
        if (vo != null) {
            Long realSessionId = chatSessionMapper.selectIdByApplicationId(sessionId);
            if (realSessionId != null) {
                ChatSession s = chatSessionMapper.selectById(realSessionId);
                if (s != null) {
                    vo.setCanSend(computeCanSend(s, userId, role));
                }
            }
            vo.setSessionType(ChatSessionType.APPLICATION);
            return vo;
        }

        throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markSessionRead(Long sessionId, Long userId, String sessionType) {
        Long realSessionId;

        // 直接会话：sessionId 即 chat_session.id，需校验参与者身份
        if (ChatSessionType.isDirect(sessionType)) {
            ChatSession session = chatSessionMapper.selectById(sessionId);
            if (session == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
            }
            validateParticipant(session, userId);
            realSessionId = session.getId();
        } else {
            // 投递会话：通过 task_application_id 解析真实会话 ID
            realSessionId = chatSessionMapper.selectIdByApplicationId(sessionId);
            if (realSessionId == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
            }
        }

        // 标记对方消息为已读
        chatMessageMapper.markAsRead(realSessionId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createChatSession(Long applicationId, Long employerId, Long seekerId) {
        // 检查是否已存在会话
        Long existingId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (existingId != null) {
            return; // 已存在，不重复创建
        }

        ChatSession chatSession = new ChatSession();
        chatSession.setTaskApplicationId(applicationId);
        chatSession.setEmployerId(employerId);
        chatSession.setSeekerId(seekerId);
        chatSession.setStatus(0);
        chatSession.setCreateTime(LocalDateTime.now());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.insert(chatSession);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createDirectSession(Long employerId, Long seekerId) {
        // 检查是否已存在直接会话
        Long existingId = chatSessionMapper.selectDirectSessionId(employerId, seekerId);
        if (existingId != null) {
            return existingId;
        }

        ChatSession chatSession = new ChatSession();
        chatSession.setTaskApplicationId(null);
        chatSession.setEmployerId(employerId);
        chatSession.setSeekerId(seekerId);
        chatSession.setStatus(0);
        chatSession.setCreateTime(LocalDateTime.now());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.insert(chatSession);
        return chatSession.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void initChatSession(Long applicationId, Long userId, Integer role) {
        // 仅 HR 可调用
        if (role != 1) {
            throw new BusinessException(ApiResult.FORBIDDEN, "仅 HR 可以创建会话");
        }

        // 检查会话是否已存在
        Long existingId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (existingId != null) {
            return; // 已存在，无需创建
        }

        // 查询投递记录，获取求职者 ID
        TaskApplication application = taskApplicationMapper.selectById(applicationId);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }

        // 校验 HR 是否为该职位所属企业的人员
        Task task = taskMapper.selectById(application.getTaskId());
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "关联职位不存在");
        }
        com.uniseek.entity.Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
        if (enterprise == null || !enterprise.getUserId().equals(userId)) {
            throw new BusinessException(ApiResult.FORBIDDEN, "您无权操作该投递的会话");
        }

        // 创建会话
        ChatSession chatSession = new ChatSession();
        chatSession.setTaskApplicationId(applicationId);
        chatSession.setEmployerId(userId);
        chatSession.setSeekerId(application.getApplicantId());
        chatSession.setStatus(0);
        chatSession.setCreateTime(LocalDateTime.now());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.insert(chatSession);
    }

    @Override
    public Long getUnreadCount(Long userId) {
        return chatMessageMapper.selectUnreadCount(userId);
    }

    /**
     * 计算当前用户是否允许在当前会话中发送消息
     * <p>HR  unrestricted；求职者仅在「未发送过消息」或「HR 已回复」时可发送。</p>
     *
     * @param session 会话实体
     * @param userId  当前用户 ID
     * @param role    当前用户角色
     * @return true 允许发送
     */
    private boolean computeCanSend(ChatSession session, Long userId, Integer role) {
        // HR 不受限制
        if (role == 1) {
            return true;
        }
        // 求职者：必须先属于该会话
        if (!session.getSeekerId().equals(userId)) {
            return false;
        }
        Long sessionId = session.getId();
        Long employerId = session.getEmployerId();

        // 统计求职者已发送的消息数
        long seekerMsgCount = chatMessageMapper.selectCount(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getSessionId, sessionId)
                        .eq(ChatMessage::getSenderId, userId));
        // 未发送过消息，允许发送第一条
        if (seekerMsgCount == 0) {
            return true;
        }
        // 已发送过消息，需等待 HR 回复后才能继续发送
        long employerMsgCount = chatMessageMapper.selectCount(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getSessionId, sessionId)
                        .eq(ChatMessage::getSenderId, employerId));
        return employerMsgCount > 0;
    }

    /**
     * 校验当前用户是否有权访问该会话
     *
     * @param sessionId     会话标识：投递会话时为 task_application_id，直接会话时为 chat_session.id
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @param sessionType   会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 会话实体
     */
    private ChatSession validateSessionAccess(Long sessionId, Long userId, Integer role, String sessionType) {
        if (sessionId == null || sessionId == 0) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 直接会话：sessionId 本身就是 chat_session.id，直接查询并校验参与者
        if (ChatSessionType.isDirect(sessionType)) {
            ChatSession session = chatSessionMapper.selectById(sessionId);
            if (session == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
            }
            validateParticipant(session, userId, role);
            return session;
        }

        // 投递会话：通过 task_application_id 解析 chat_session.id，避免两个主键空间数值重叠
        Long sessionIdByApplication = chatSessionMapper.selectIdByApplicationId(sessionId);
        ChatSession session = sessionIdByApplication == null
                ? null : chatSessionMapper.selectById(sessionIdByApplication);
        if (session != null) {
            validateApplicationAccess(session, sessionId, userId, role);
            return session;
        }

        throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
    }

    private void validateParticipant(ChatSession session, Long userId, Integer role) {
        if (role == 1 && !session.getEmployerId().equals(userId) ||
            role == 0 && !session.getSeekerId().equals(userId)) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
        }
    }

    /**
     * 校验当前用户是否为该会话的参与者（无需角色信息）
     */
    private void validateParticipant(ChatSession session, Long userId) {
        if (!userId.equals(session.getEmployerId()) && !userId.equals(session.getSeekerId())) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
        }
    }

    private void validateApplicationAccess(ChatSession session, Long applicationId, Long userId, Integer role) {
        // 职位投递会话权限校验
        TaskApplication application = taskApplicationMapper.selectById(applicationId);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }
        if (role == 1) {
            Task task = taskMapper.selectById(application.getTaskId());
            if (task == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "关联职位不存在");
            }
            com.uniseek.entity.Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
            if (enterprise == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "企业信息不存在");
            }
            if (!enterprise.getUserId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
        } else {
            if (!session.getSeekerId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
        }

    }

    @Override
    public ChatMessageVO sendStatusChangeSystemMessage(Long applicationId, Long hrUserId, String content) {
        // 1. 查询关联的聊天会话
        ChatSession chatSession = chatSessionMapper.selectOne(
                new LambdaQueryWrapper<ChatSession>()
                        .eq(ChatSession::getTaskApplicationId, applicationId));
        if (chatSession == null) {
            log.warn("投递记录 {} 无关联聊天会话，跳过系统消息发送", applicationId);
            return null;
        }

        // 2. 创建消息记录
        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSessionId(chatSession.getId());
        chatMessage.setSenderId(hrUserId);
        chatMessage.setMessageType(0); // 文本消息
        chatMessage.setContent(content);
        chatMessage.setIsRead(0);
        chatMessage.setSendTime(LocalDateTime.now());
        chatMessageMapper.insert(chatMessage);

        // 3. 更新会话最后消息
        chatSession.setLastMessage(content);
        chatSession.setLastMessageTime(chatMessage.getSendTime());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.updateById(chatSession);

        // 4. 构建 VO
        ChatMessageVO vo = buildChatMessageVO(chatMessage);

        // 5. WebSocket 推送给求职者
        try {
            chatWebSocketHandler.notifyNewMessage(
                    chatSession.getSeekerId(),
                    vo,
                    applicationId,
                    ChatSessionType.APPLICATION
            );
        } catch (Exception e) {
            log.warn("WebSocket 推送系统消息失败: applicationId={}, error={}", applicationId, e.getMessage());
        }

        return vo;
    }

    /**
     * 构建 ChatMessageVO
     *
     * @param msg 消息实体
     * @return 消息 VO
     */
    private ChatMessageVO buildChatMessageVO(ChatMessage msg) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setId(msg.getId());
        vo.setSenderId(msg.getSenderId());
        vo.setMessageType(msg.getMessageType());
        vo.setContent(msg.getContent());
        vo.setIsRead(msg.getIsRead());
        vo.setSendTime(msg.getSendTime());

        // 查询发送者信息
        User sender = userMapper.selectById(msg.getSenderId());
        if (sender != null) {
            vo.setSenderName(sender.getNickname());
            vo.setSenderAvatar(sender.getAvatarUrl());
        }
        return vo;
    }

    /**
     * 获取求职者的简历附件 URL
     */
    private String getSeekerResumeUrl(Long seekerId) {
        Resume resume = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>().eq(Resume::getUserId, seekerId));
        return resume != null ? resume.getAttachmentUrl() : null;
    }

    /**
     * 构建直接会话的 ChatSessionVO
     */
    private ChatSessionVO buildDirectSessionVO(ChatSession session, Long userId, Integer role) {
        Long counterpartId = role == 1 ? session.getSeekerId() : session.getEmployerId();
        User user = userMapper.selectById(counterpartId);
        ChatSessionVO vo = new ChatSessionVO();
        vo.setApplicationId(session.getId());
        vo.setCounterpartId(counterpartId);
        vo.setCounterpartName(user != null ? user.getNickname() : "未知用户");
        vo.setCounterpartAvatar(user != null ? user.getAvatarUrl() : null);
        vo.setLastMessage(session.getLastMessage());
        vo.setLastMessageTime(session.getLastMessageTime());
        vo.setUnreadCount(0);
        vo.setCanSend(true);
        vo.setSessionType(ChatSessionType.DIRECT);
        return vo;
    }
}
